require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_params = []
    params.each do |key, value|
      where_params << "#{key.to_s} = '#{value.to_s}'"
    end

    result_db = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_params.join(" AND ")}
    SQL
    
    result_db.map do |result|
      self.new(result)
    end
  end
end

class SQLObject
  
  extend Searchable
  
end
