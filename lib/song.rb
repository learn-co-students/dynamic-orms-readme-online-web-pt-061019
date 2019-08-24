require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name
    self.to_s.downcase.pluralize
  end

  #Return value of this method is: ["id", "name", "album"] if calling on a songs table.
  def self.column_names
    DB[:conn].results_as_hash = true

    #this bit grabs a huge amount of key-value info. The key "name" gives us column name, and "type" gives type
    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  #the conversion to symbols here is bc attr_accessors must be symbols
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  #options defaults to empty hash but usually we'll be passing a hash in
  def initialize(options={})
    #using the send keyword to set the key in this hash to the variable and then setting that equal to the value
    #like name = the name value passed in. This works as long as there are attr_accessors for everything.
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  #this is grabbing the values we want to insert into table for making new record
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      #the unless nil is to deal with id, which isn't set at this point bc this is for INSERT
      #invoking attr_reader methods without having to name them by using send
      #return value wrapped in single quotes within string bc they need to be strings within SQL string
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    #values array made into string bc SQL queries need to be string
    values.join(", ")
  end

  #we are deleting id from here bc the table generates its own id
  #this also turns the array into a comma-separated string so it's formatted like argument
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



