require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    param_hash = []
    where_hash = []
    params.each do |k, v|
      param_hash << v
      where_hash << "#{k} = ?"
    end

    param_hash.join(", ")
    where_hash.join(" AND ")

    DBConnection.execute2(<<-SQL, param_hash)
      SELECT *
      FROM "#{self.table_name}"
      WHERE "#{where_hash}"
    SQL
  end
end

class SQLObject
  # Mixin Searchable here...
  include Searchable
end
