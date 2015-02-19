module ActiveRecord
  module ConnectionAdapters
    module Mysql2SpatialAdapter
      module SchemaStatements
        def create_table_definition(name, temporary, options, as = nil)
          Mysql2SpatialAdapter::TableDefinition.new(native_database_types, name, temporary, options, as)
        end

        def update_table_definition(table_name, base)
          Mysql2SpatialAdapter::Table.new(table_name, base)
        end

        def native_database_types
          super.merge({
            :point       => { :name => "point" },
            :line_string => { :name => "linestring" },
            :polygon     => { :name => "polygon" },
            :geometry    => { :name => "geometry" }
          })
        end

        # override
        def columns(table_name, name = nil)
          sql = "SHOW FULL FIELDS FROM #{quote_table_name(table_name)}"
          execute_and_free(sql, 'SCHEMA') do |result|
            each_hash(result).map do |field|
              field_name = respond_to?(:set_field_encoding) ? set_field_encoding(field[:Field]) : field[:Field]
              sql_type = field[:Type]
              cast_type = lookup_cast_type(sql_type)
              new_column(table_name, field_name, field[:Default], sql_type,
                         cast_type, field[:Null] == "YES", field[:Collation], field[:Extra])
            end
          end
        end

        def new_column(table_name, field, default, sql_type = nil, cast_type = nil, null = true, collation = "", extra = "")
          SpatialColumn.new(@rgeo_factory_settings, table_name, field, default, sql_type, cast_type, null, collation, extra)
        end

        def type_to_sql(type_, limit_=nil, precision_=nil, scale_=nil)
          if (spatial_column_constructor(type_.to_sym))
            type_ = limit_[:type] || type_ if limit_.is_a?(::Hash)
            type_ = 'geometry' if type_.to_s == 'spatial'
            type_ = type_.to_s.gsub('_', '').upcase
          end
          super(type_, limit_, precision_, scale_)
        end

        # INDEXES
        def add_index(table_name_, column_name_, options_={})
          if options_[:spatial]
            index_name_ = index_name(table_name_, :column => Array(column_name_))
            if ::Hash === options_
              index_name_ = options_[:name] || index_name_
            end
            execute "CREATE SPATIAL INDEX #{index_name_} ON #{table_name_} (#{Array(column_name_).join(", ")})"
          else
            super
          end
        end

        def initialize_type_map(map)
          super

          %w(
            geometry
            geometry_collection
            line_string
            linestring
            multi_line_string
            multi_point
            multi_polygon
            point
            polygon
          )
            .each do |geo_type|
            map.register_type(geo_type) do |oid, _, sql_type|
              Spatial.new(oid, sql_type)
            end
          end
        end

        def lookup_cast_type(sql_type)
          super(sql_type)
        rescue NoMethodError
          nil
        end
      end
    end
  end
end
