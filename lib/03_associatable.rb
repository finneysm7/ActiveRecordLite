require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options[:class_name] ||= "#{name}".camelcase.singularize
    options[:foreign_key] ||= ("#{name}".camelcase.underscore + "_id")
      .to_sym
    options[:primary_key] ||= "id".to_sym
    @class_name = options[:class_name]
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]   
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options[:class_name] ||= "#{name}".camelcase.singularize
    options[:foreign_key] ||= ("#{self_class_name}"
      .singularize.camelcase.underscore + "_id").to_sym
    options[:primary_key] ||= "id".to_sym
    @class_name = options[:class_name]
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # Construct a BelongsToOptions instance.
    assoc_options
    bto = BelongsToOptions.new(name, options)
    
    @options[name] = bto
    define_method(name) do 
      # self == cat instance
      bto.model_class.where({bto.primary_key => self.send(bto.foreign_key)}).first

      # Human.where("id = #{self.human_id}").first
      
      # BelongsToOptions.send(:new, options)
    end
  end

  def has_many(name, options = {})
    hm_options = HasManyOptions.new(name, self, options)
    define_method(name) do
      hm_options.model_class.where({hm_options.foreign_key => self.send(hm_options.primary_key)})
    end
  end

  def assoc_options
    @options ||= {}
  end
end

class SQLObject
  extend Associatable
end
