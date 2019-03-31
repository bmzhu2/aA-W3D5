require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @cols ||= DBConnection.execute2(<<-SQL, )
      SELECT *
      FROM "#{table_name}"
      LIMIT 0
    SQL

    @cols[0].map! {|el| el.to_sym}
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}") {attributes[col]}
      define_method("#{col}=") {|val| attributes[col] = val}
    end
  end

  def self.table_name=(table_name)
    # instance_variable_set("@#{name}", table_name)
  end

  def self.table_name
    self.name.downcase + "s"
    # self.name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL, )
      SELECT *
      FROM "#{table_name}"
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map {|obj| new(obj)}
  end

  def self.find(id)
    return nil unless id
    result = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM "#{table_name}"
      WHERE id = ?
    SQL
    return nil unless result.length > 0
    parse_all(result).first
  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k.to_sym)
      self.send("#{k}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |col|
      self.send("#{col}")
    end
  end

  def insert
    cols = self.class.columns
    question_marks = "(" + (["?"] * cols.size).join(", ") + ")"
    col_names = "(" + cols.join(", ") + ")"

    

    attr_values = attribute_values
    attr_values[0] = self.class.all.length + 1

    DBConnection.execute(<<-SQL, *attr_values)
      INSERT INTO 
        #{self.class.table_name} #{col_names}
      VALUES 
        #{question_marks}
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_sets = self.class.columns.map {|col| "#{col} = ?"}[1..-1].join(", ")
    attr_values = attribute_values
    attr_values = attr_values[1..-1] + [attr_values[0]]

    DBConnection.execute(<<-SQL, *attr_values)
      UPDATE
        #{self.class.table_name} 
      SET 
        #{col_sets}
      WHERE
        id = ?
    SQL
  end

  def save
    if id
      update
    else
      insert
    end
  end
end
