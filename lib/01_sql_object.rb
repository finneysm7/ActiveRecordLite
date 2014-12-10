require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    final = result[0].map do |name|
      name.to_sym
    end
    final
  end
  
  def self.finalize!
    self.columns.each do |name|
      define_method(name) do #need to make it into two methods
        # instance_variable_get(@attributes["@#{name}"])
        self.attributes[name]
      end
      define_method("#{name}=") do |argument|
        self.attributes[name] = argument
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    result = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
      #{self.table_name}
    SQL
    self.parse_all(result)
  end

  def self.parse_all(results)
    results.map do |el|
      self.new(el)
    end
  end

  def self.find(id)
    
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    self.parse_all(result)[0]
  end

  def initialize(params = {})
    cols = self.class.columns
    p "cols: #{cols}"
    p "keys: #{params.keys.map(&:to_sym)}"
    params.each do |key, val|
      attr_name = key.to_sym
      if cols.include?(attr_name)
        self.send("#{key}=".to_sym, val)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end
  

  def attribute_values
    result = []
    self.class.columns.map do |el|
      result << self.send(el)
    end
    p result
  end

  def insert
    cols = self.class.columns
    q_arr = []
    cols.length.times { q_arr << "?" }
    col_string = cols.join(',')
    result = DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_string})
    VALUES
      (#{q_arr.join(',')})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns
    col_string = cols.map do |attr_name|
      "#{attr_name} = ?"
    end.join(',')
    result = DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_string}
      WHERE
        #{self.class.table_name}.id = ?
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
