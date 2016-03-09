require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL

    @columns[0].map { |col| col.to_sym }
  end

  def self.finalize!

    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end

      define_method("#{column}=") do |new_value|
        self.attributes[column] = new_value
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
      "#{@table_name}".*
    FROM
      "#{@table_name}"
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    objects = []
    results.each do |result|
        new_object = self.new(result)
        objects << new_object
    end
    objects
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{self.table_name}"
      WHERE
        "#{self.table_name}".id = ?
    SQL

    result.first.nil? ? nil : self.new(result.first)
  end

  def initialize(params = {})
      params.each do |attr_name, value|
        raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name.to_sym)
        self.send "#{attr_name}=", value
      end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    col_names = self.class.columns.drop(1).join(", ")
    question_marks = (["?"] * self.class.columns.drop(1).count).join(",")

      DBConnection.execute(<<-SQL, *attribute_values)
        INSERT INTO
          #{self.class.table_name} (#{col_names})
        VALUES
          (#{question_marks})
      SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns

    set_values = []
    col_names.each do |col|
      set_values << "#{col} = ?"
    end
    set_values

    query = <<-SQL
        UPDATE
          #{self.class.table_name}
        SET
          #{set_values.join(", ")}
        WHERE
          id = "#{self.id}"
      SQL

      DBConnection.execute(query, *attribute_values)

  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
