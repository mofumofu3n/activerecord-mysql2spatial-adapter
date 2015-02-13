module ActiveRecord
  module ConnectionAdapters
    module Mysql2SpatialAdapter
      class TableDefinition < ConnectionAdapters::TableDefinition
        def point(name, options = {})
          column(name, :point, options)
        end

        def line_string(name, options = {})
          column(name, :line_string, options)
        end

        def polygon(name, options = {})
          column(name, :polygon, options)
        end

        def geometry(name, options = {})
          column(name, :geometry, options)
        end
        alias_method :spatial, :geometry
      end

      class Table < ConnectionAdapters::Table
        def point(name, options = {})
          column(name, :point, options)
        end

        def line_string(name, options = {})
          column(name, :line_string, options)
        end

        def polygon(name, options = {})
          column(name, :polygon, options)
        end

        def geometry(name, options = {})
          column(name, :geometry, options)
        end
        alias_method :spatial, :geometry
      end
    end
  end
end
