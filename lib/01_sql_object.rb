require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  
  attr_accessor :table_name, :attributes
  
  def self.columns
    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    columns.first.map{|column| column.to_sym}
    #In SQL queries, the first row identifies the columns. The following rows will
    #be stored in hashes representing the remaining data in our tables.
  end

  def self.finalize!
    
    self.columns.each do |column| 
      #The each statement creates attr_accessors for every column in our table.
      
      define_method("#{column}") do
        attributes[column]
      end
      
      define_method("#{column}=") do |variable|
        attributes[column] = variable
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name.to_s
  end

  def self.table_name
    @table_name ||= self.to_s.downcase.pluralize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    results.map do |result|
      self.new(result)
    end
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL
    
    return nil if result.empty?
    self.new(result.first)
    #Result will be an array with ONE hash. Calling .first will set up our 
    #initializing params.
  end

  def initialize(params = {})
    params.keys.each do |key|
      #key should represent the column
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym)
      self.class.finalize!
      send("#{key}=", params[key])
    end
  end

  def attributes
    @attributes ||= {:id => nil}
  end

  def attribute_values
    attribute_values = []
    attributes.map do |key, value|
      attribute_values << value  
    end
    attribute_values
  end

  def insert
    last_id = DBConnection.last_insert_row_id
    insert_values = attribute_values
    insert_values.shift
    #When we insert a new object into the database, the ID will be nil by default.
    #We don't want to insert that value into our database, so we are deleting it.
  
    DBConnection.execute(<<-SQL)
      INSERT INTO
        #{self.class.table_name} (#{self.class.columns.join(', ')})
      VALUES
        ('#{last_id}','#{insert_values.join("','")}')
    SQL
    
    attributes[:id] = last_id
    #Making sure when object is saved into database, we record its ID attribute.
  end

  def update
    DBConnection.execute(<<-SQL)
      UPDATE
        #{self.class.table_name}
      SET
        #{self.class.columns.map do |col|
          col.to_s + " = " + "'" + attributes[col].to_s + "'"
        end.join(', ')}
      WHERE
        id = #{attributes[:id]}
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
