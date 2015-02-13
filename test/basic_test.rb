# a  -----------------------------------------------------------------------------
#
# Tests for the Mysql2Spatial ActiveRecord adapter
#
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------

require 'test_helper'

class TestBasic < ::Minitest::Unit::TestCase

  DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
  include RGeo::ActiveRecord::AdapterTestHelper

  def populate_ar_class(content_)
    klass_ = create_ar_class
    case content_
    when :latlon_point
      klass_.connection.create_table(:spatial_test) do |t_|
        t_.column 'latlon', :point
      end
    end
    klass_
  end

  def test_version
    assert(::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::VERSION != nil)
  end

  def test_create_simple_geometry
    klass_ = create_ar_class
    klass_.connection.create_table(:spatial_test) do |t_|
      t_.column 'latlon', :geometry
    end
    assert_equal(::RGeo::Feature::Geometry, klass_.columns.last.geometric_type)
    assert(klass_.attribute_method?('latlon'))
  end


  def test_create_point_geometry
    klass_ = create_ar_class
    klass_.connection.create_table(:spatial_test) do |t_|
      t_.column 'latlon', :point
    end
    assert_equal(::RGeo::Feature::Point, klass_.columns.last.geometric_type)
    assert(klass_.attribute_method?('latlon'))
  end

  def test_create_geometry_with_index
    klass_ = create_ar_class
    klass_.connection.create_table(:spatial_test, :options => 'ENGINE=MyISAM') do |t_|
      t_.column 'latlon', :geometry, :null => false
    end
    klass_.connection.change_table(:spatial_test) do |t_|
      t_.index([:latlon], :spatial => true)
    end
    assert(klass_.connection.indexes(:spatial_test).last.type == :spatial)
  end


  def test_set_and_get_point
    create_model
    obj_ = SpatialModel.new
    assert_nil(obj_.latlon)
    obj_.latlon = @factory.point(1, 2)
    assert_equal(@factory.point(1, 2), obj_.latlon)
    assert_equal(3785, obj_.latlon.srid)
  end

  def test_set_and_get_point_from_wkt
    create_model
    obj_ = SpatialModel.new
    assert_nil(obj_.latlon)
    obj_.latlon = 'POINT(1 2)'
    assert_equal(@factory.point(1, 2), obj_.latlon)
    assert_equal(3785, obj_.latlon.srid)
  end

  def test_save_and_load_point
    create_model
    obj = SpatialModel.new
    obj.latlon = @factory.point(1, 2)
    obj.save!
    id = obj.id
    obj2 = SpatialModel.find(id)
    assert_equal(@factory.point(1, 2), obj2.latlon)
    assert_equal(3785, obj2.latlon.srid)
  end

  # TODO: make pass
  # def test_save_and_load_geographic_point
  #   create_model
  #   obj = SpatialModel.new
  #   obj.latlon_geo = geographic_factory.point(1.0, 2.0)
  #   obj.save!
  #   id = obj.id
  #   obj2 = SpatialModel.find(id)
  #   assert_equal geographic_factory.point(1.0, 2.0), obj2.latlon_geo
  #   assert_equal 4326, obj2.latlon_geo.srid
  #   # assert_equal false, RGeo::Geos.is_geos?(obj2.latlon_geo)
  # end

  def test_save_and_load_point_from_wkt
    create_model
    obj_ = SpatialModel.new
    obj_.latlon = 'POINT(1 2)'
    obj_.save!
    id_ = obj_.id
    obj2_ = SpatialModel.find(id_)
    assert_equal(@factory.point(1, 2), obj2_.latlon)
    assert_equal(3785, obj2_.latlon.srid)
  end

  def test_set_point_bad_wkt
    create_model
    obj = SpatialModel.create(latlon: 'POINT (x)')
    assert_nil obj.latlon
  end

  # TODO
  # def test_set_point_wkt_wrong_type
  #   klass_ = populate_ar_class(:latlon_point)
  #   assert_raises(ActiveRecord::StatementInvalid) do
  #     klass_.create(latlon: 'LINESTRING(1 2, 3 4, 5 6)')
  #   end
  # end

  def test_custom_factory
    create_model
    factory = RGeo::Geographic.simple_mercator_factory
    MercatorModel.connection.create_table(:spatial_models, force: true) do |t|
      t.column(:latlon, :point, srid: 4326)
    end
    assert_equal factory, MercatorModel.rgeo_factory_for_column(:latlon)
    object = MercatorModel.new
    assert_equal factory, object.class.rgeo_factory_for_column(:latlon)
  end

  # def test_readme_example
    # create_model
    # GeographicModel.connection.change_table(:spatial_models) do |t|
    #   t.change :geo_latlon, :point, null: false
    #   t.index(:latlon, :spatial => true)
    # end
    # assert_includes GeographicModel.columns.map(&:name), "shape"
    # rec_ = GeographicModel.new
    # rec_.latlon_geo = 'POINT(-122 47)'
    # loc_ = rec_.latlon_geo
    # assert_equal(47, loc_.latitude)
  # end

  def test_point_to_json
    create_model
    obj = SpatialModel.new
    assert_match(/"latlon":null/, obj.to_json)
    obj.latlon = @factory.point(1.0, 2.0)
    assert_match(/"latlon":"POINT\s\(1\.0\s2\.0\)"/, obj.to_json)
  end

  def test_custom_column
    create_model
    rec = SpatialModel.new
    rec.latlon = 'POINT(0 0)'
    rec.save
    refute_nil SpatialModel.select("CURRENT_TIMESTAMP as ts").first.ts
  end

  def test_create_simple_geometry_using_shortcut
    create_model
    SpatialModel.connection.change_table(:spatial_models) do |t_|
      t_.geometry 'geometry_shortcut'
    end
    assert_equal(::RGeo::Feature::Geometry, SpatialModel.columns.last.geometric_type)
    assert(SpatialModel.attribute_method?('geometry_shortcut'))
  end

  def test_create_point_geometry_using_shortcut
    create_model
    SpatialModel.connection.change_table(:spatial_models) do |t|
      t.point 'latlon_shortcut'
    end
    assert_equal(::RGeo::Feature::Point, SpatialModel.columns.last.geometric_type)
    assert(SpatialModel.attribute_method?(:latlon_shortcut))
  end

  def test_create_geometry_using_limit
    create_model
    SpatialModel.connection.change_table(:spatial_models) do |t_|
      t_.spatial 'geom', :limit => {:type => :line_string}
    end
    SpatialModel.reset_column_information
    assert_equal(::RGeo::Feature::LineString, SpatialModel.columns.last.geometric_type)
    assert(SpatialModel.attribute_method?(:geom))
  end

  private
  def create_model
    SpatialModel.connection.create_table(:spatial_models, force: true, :options => 'ENGINE=MyISAM' ) do |t|
      t.point 'latlon', srid: 3785
      t.point 'latlon_geo', srid: 4326, geographic: true
      t.line_string :path
      t.geometry :shape
    end
    SpatialModel.reset_column_information
  end
end

