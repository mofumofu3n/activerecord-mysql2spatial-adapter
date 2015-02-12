require 'minitest/autorun'
require 'minitest/pride'
require 'rgeo/active_record/adapter_test_helper'

begin
  require 'pry'
rescue LoadError
  # ignore
end


DATABASE_CONFIG_PATH = File.dirname(__FILE__) << '/database.yml'
class SpatialModel < ActiveRecord::Base
  establish_connection YAML.load_file(DATABASE_CONFIG_PATH)
end

class MercatorModel < ActiveRecord::Base
  establish_connection YAML.load_file(DATABASE_CONFIG_PATH)
  self.table_name = :spatial_models
  set_rgeo_factory_for_column(:latlon, RGeo::Geographic.simple_mercator_factory)
end

class GeographicModel < ActiveRecord::Base
  establish_connection YAML.load_file(DATABASE_CONFIG_PATH)
  self.table_name = :spatial_models
  self.rgeo_factory_generator = ::RGeo::Geos.method(:factory)
  set_rgeo_factory_for_column(:latlon, ::RGeo::Geographic.spherical_factory)
end

class TestHelpers
  def self.factory
    RGeo::Cartesian.preferred_factory(srid: 3785)
  end

  def geographic_factory
    RGeo::Geographic.spherical_factory(srid: 4326)
  end
end
