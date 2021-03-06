require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

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
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})

    @foreign_key = (options[:foreign_key] ? options[:foreign_key] : "#{name.to_s.underscore}_id".to_sym)
    @class_name = (options[:class_name] ? options[:class_name] : name.to_s.camelcase)
    @primary_key = (options[:primary_key] ? options[:primary_key] : :id)

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})

    @foreign_key = (options[:foreign_key] ? options[:foreign_key] : "#{self_class_name.to_s.underscore}_id".to_sym)
    @class_name = (options[:class_name] ? options[:class_name] : name.to_s.singularize.capitalize)
    @primary_key = (options[:primary_key] ? options[:primary_key] : :id)

  end
end

module Associatable

  def belongs_to(name, options = {})

    options = BelongsToOptions.new(name, options)
    self.assoc_options["#{name}".to_sym] = options

    define_method(name) do
      foreign_key = options.send(:foreign_key)
      model_class = options.model_class

      model_class.where(options.primary_key => self.send(options.foreign_key)).first
    end


  end

  def has_many(name, options = {})

    options = HasManyOptions.new(name, self.to_s.constantize, options)
    define_method(name) do
      foreign_key = options.send(:foreign_key)
      options.model_class.where(options.foreign_key => self.send(options.primary_key))
    end

  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
