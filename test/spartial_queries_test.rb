# -----------------------------------------------------------------------------
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
;

require 'test_helper'

class TestSpatialQueries < ::Minitest::Unit::TestCase
  DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
  include RGeo::ActiveRecord::AdapterTestHelper

  def populate_ar_class(content_)
    klass_ = create_ar_class
    case content_
    when :latlon_point
      klass_.connection.create_table(:spatial_test) do |t_|
        t_.column 'latlon', :point
      end
    when :path_linestring
      klass_.connection.create_table(:spatial_test) do |t_|
        t_.column 'path', :line_string
      end
    end
    klass_
  end

  def test_query_point
    create_model
    obj = SpatialModel.new
    obj.latlon = @factory.point(1, 2)
    obj.save!
    id = obj.id
    obj2 = SpatialModel.where(:latlon => @factory.point(1, 2)).first
    refute_nil(obj2)
    assert_equal(id, obj2.id)
    obj3 = SpatialModel.where(:latlon => @factory.point(2, 2)).first
    assert_nil(obj3)
  end

  def test_query_point_wkt
    klass = populate_ar_class(:latlon_point)
    obj = klass.new
    obj.latlon = @factory.point(1, 2)
    obj.save!
    id = obj.id
    obj2 = klass.where(:latlon => 'POINT(1 2),3785').first
    refute_nil(obj2)
    assert_equal(id, obj2.id)
    obj3 = klass.where(:latlon => 'POINT(2 2),3785').first
    assert_nil(obj3)
  end


  if ::RGeo::ActiveRecord.spatial_expressions_supported?
    def test_query_st_distance
      create_model
      obj = SpatialModel.new
      obj.latlon = @factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = SpatialModel.where(SpatialModel.arel_table[:latlon].st_distance('POINT(2 3),3785').lt(2)).first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = SpatialModel.where(SpatialModel.arel_table[:latlon].st_distance('POINT(2 3),3785').gt(2)).first
      assert_nil(obj3)
    end

    def test_query_st_distance_from_constant
      create_model
      obj = SpatialModel.new
      obj.latlon = @factory.point(1.0, 2.0)
      obj.save!
      id = obj.id
      obj2 = SpatialModel.where(::Arel.spatial('POINT(2 3),3785').st_distance(SpatialModel.arel_table[:latlon]).lt(2)).first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = SpatialModel.where(::Arel.spatial('POINT(2 3),3785').st_distance(SpatialModel.arel_table[:latlon]).gt(2)).first
      assert_nil(obj3)
    end

    def test_query_st_length
      create_model
      obj = SpatialModel.new
      obj.path = @factory.line(@factory.point(1, 2), @factory.point(3, 2))
      obj.save!
      id = obj.id
      obj2 = SpatialModel.where(SpatialModel.arel_table[:path].st_length.eq(2)).first
      refute_nil(obj2)
      assert_equal(id, obj2.id)
      obj3 = SpatialModel.where(SpatialModel.arel_table[:path].st_length.gt(3)).first
      assert_nil(obj3)
    end
  else
    puts "WARNING: The current Arel does not support named functions. Spatial expression tests skipped."
  end

  private
  def create_model
    SpatialModel.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'latlon', :point
      t.column 'path', :line_string
      # t.column 'latlon', :st_point, srid: 3785
      # t.column 'path', :line_string, srid: 3785
    end
    SpatialModel.reset_column_information
  end
end


