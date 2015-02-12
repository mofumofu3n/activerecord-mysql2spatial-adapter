module ActiveRecord
  module ConnectionAdapters
    module Mysql2SpatialAdapter
      class Spatial < Type::Value
        def initialize(oid, sql_type)
          @geo_type, @srid = oid.split(",")
          @srid = 3785 if @srid.blank?
          @factory_generator = RGeo::Geographic.spherical_factory(srid: 4326) if oid =~ /geography/
        end

        def spatial?
          true
        end
      end
    end
  end
end
