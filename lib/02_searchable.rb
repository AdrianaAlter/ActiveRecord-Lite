require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
  def where(params)
    where_line = []
    params.each { |key, value| where_line << "#{key} = '#{value}'" }
    where_line = where_line.join(" AND ")
    query = <<-SQL
      SELECT
      *
      FROM
      #{self.table_name}
      WHERE
      #{where_line}
      SQL

    search_result = DBConnection.execute(query)
    self.parse_all(search_result)
  end
end

class SQLObject
  extend Searchable
end
