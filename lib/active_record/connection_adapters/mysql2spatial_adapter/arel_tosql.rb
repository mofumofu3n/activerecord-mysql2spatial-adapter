# -----------------------------------------------------------------------------
#
# Mysql2Spatial adapter for ActiveRecord
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


# :stopdoc:

module Arel
  module Visitors

    class MySQL2Spatial < MySQL

      if ::Arel::Visitors.const_defined?(:BindVisitor)
        include ::Arel::Visitors::BindVisitor
      end

      FUNC_MAP = {
        'st_wkttosql' => 'GeomFromText',
        'st_wkbtosql' => 'GeomFromWKB',
        'st_length' => 'GLength',
        'st_distance' => 'ST_Distance',
      }

      include ::RGeo::ActiveRecord::SpatialToSql

      def st_func(standard_name)
        if (name = FUNC_MAP[standard_name.downcase])
          name
        elsif standard_name =~ /^st_(\w+)$/i
          $1
        else
          standard_name
        end
      end

      # Override equality nodes to use the ST_Equals function if at least
      # one of the operands is a spatial node.
      def visit_Arel_Nodes_Equality(node, collector = nil)
        check_equality_for_rgeo(node, false) || super(node)
      rescue ArgumentError
        super(node, collector)
      end

      # Override equality nodes to use the ST_Equals function if at least
      # one of the operands is a spatial node.

      def visit_Arel_Nodes_NotEqual(node_)
        _check_equality_for_rgeo(node_, true) || super
      end

      def visit_RGeo_ActiveRecord_SpatialNamedFunction(node, collector = nil)
        aggregate(st_func(node.name), node, collector)
      rescue NoMethodError
        super(node)
      rescue ArgumentError
        super(node, collector)
      end

      def visit_String(node, collector)
        collector << "#{st_func('GeomFromText')}(#{quote(node)})"
      end

      private
      # Returns a true value if the given node is of spatial type-- that
      # is, if it is a spatial literal or a reference to a spatial
      # attribute.
      def node_has_spatial_type?(node)
        case node
        when ::Arel::Attribute
          @connection.instance_variable_set(:@_getting_columns, true)
          begin
            col = column_for(node)
            col && col.respond_to?(:spatial?) && col.spatial? ? true : false
          ensure
            @connection.instance_variable_set(:@_getting_columns, false)
          end
        when ::RGeo::ActiveRecord::SpatialNamedFunction
          node.spatial_result?
        when ::RGeo::ActiveRecord::SpatialConstantNode, ::RGeo::Feature::Instance
          true
        else
          false
        end
      end

      def check_equality_for_rgeo(node, negate)  # :nodoc:
        left = node.left
        right = node.right
        if !@connection.instance_variable_get(:@_getting_columns) &&
            !right.nil? && (node_has_spatial_type?(left) || node_has_spatial_type?(right))
          "#{negate ? 'NOT ' : ''}#{st_func('ST_Equals')}(#{visit_in_spatial_context(left)}, #{visit_in_spatial_context(right)})"
        else
          false
        end
      end

    end

    VISITORS['mysql2spatial'] = ::Arel::Visitors::MySQL2Spatial

  end
end

# :startdoc:
