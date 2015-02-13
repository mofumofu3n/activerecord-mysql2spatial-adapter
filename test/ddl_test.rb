require 'test_helper'
class DDLTest < Minitest::Unit::TestCase  # :nodoc:
  def test_type_to_sql
    adapter = SpatialModel.connection
    assert_equal "POINT", adapter.type_to_sql(:point)
  end
end

