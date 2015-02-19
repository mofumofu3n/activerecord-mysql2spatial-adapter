module ActiveRecord
  module ConnectionAdapters
    module Mysql2SpatialAdapter
      class Spatial < Type::Value
        def initialize(oid, sql_type)
          @geo_type, @srid = oid.split(",")
          @srid = 3785 if @srid.blank?
          @factory_generator = RGeo::Geographic.spherical_factory(srid: 4326) if oid =~ /geography/
        end

        def type_cast_for_database(value)
          return if value.nil?
          geo_value = type_cast(value)

          # TODO - only valid types should be allowed
          # e.g. linestring is not valid for point column
          # raise "maybe should raise" unless RGeo::Feature::Geometry.check_type(geo_value)

          RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true)
            .generate(geo_value)
        end

        def type_cast_from_database(value)
          cast_value(value)
        end

        def type_cast(value)
          return if value.nil?
          String === value ? parse_wkt(value) : value
        end

        def cast_value(value)
          return if value.nil?
          factory = @factory_generator || RGeo::ActiveRecord::RGeoFactorySettings.new
          SpatialColumn.convert_to_geometry(value, factory)
          # RGeo::WKRep::WKBParser.new(@factory_generator, support_ewkb: true).parse(value)
        rescue RGeo::Error::ParseError
          puts "\ncast failed!!\n\n"
          nil
        end

        # convert WKT string into RGeo object
        def parse_wkt(string)
          value, srid = string.split(",")
          @srid = srid if srid.present?
          # factory = factory_settings.get_column_factory(table_name, column, constraints)
          factory = @factory_generator || RGeo::ActiveRecord::RGeoFactorySettings.new
          wkt_parser(factory, value).parse(value)
        rescue RGeo::Error::ParseError
          nil
        end

        def binary?(string)
          string[0] == "\x00" || string[0] == "\x01" || string[0, 4] =~ /[0-9a-fA-F]{4}/
        end

        def wkt_parser(factory, string)
          if binary?(string)
            RGeo::WKRep::WKBParser.new(factory, support_ewkb: true, default_srid: @srid)
          else
            RGeo::WKRep::WKTParser.new(factory, support_ewkt: true, default_srid: @srid)
          end
          # Spatial.convert_to_geometry(string, factory_settings)
        end

        def spatial?
          true
        end
      end
    end
  end
end
