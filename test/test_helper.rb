require 'minitest/autorun'
require 'minitest/pride'
require 'rgeo/active_record/adapter_test_helper'

begin
  require 'byebug'
rescue LoadError
  # ignore
end


DATABASE_CONFIG_PATH = File.dirname(__FILE__) << '/database.yml'
class SpatialModel < ActiveRecord::Base
  establish_connection YAML.load_file(DATABASE_CONFIG_PATH)
end

class TestHelpers
  def self.factory
    RGeo::Cartesian.preferred_factory(srid: 3785)
  end

  def geographic_factory
    RGeo::Geographic.spherical_factory(srid: 4326)
  end
end
