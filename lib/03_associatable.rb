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
    model_class.table_name ||= @class_name.downcase.pluralize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @primary_key = options[:primary_key] ||= :id
    @class_name = options[:class_name] ||= name.camelize.titleize
    @foreign_key = options[:foreign_key] ||= name.foreign_key.to_sym
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @primary_key = options[:primary_key] ||= :id
    @class_name = options[:class_name] ||= name.singularize.titleize
    @foreign_key = options[:foreign_key] ||= self_class_name.foreign_key.to_sym
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    association = BelongsToOptions.new(name.to_s, options)
    #Variable 'name' is a symbol. This needs to be converted to string.

    define_method("#{name}") do

      foreign_key_value = send(association.foreign_key)
      # association.foreign.key is the foreign key symbol, not the value.
      # As a result, we use the 'send' method to fetch the foreign key's value
      # We will then use this value in our 'where'
      
      result = association.model_class.where(id: foreign_key_value).first
      # We use the .first method because where returns an array of objects.
      # Belongs_to associations should only return ONE object.
    end
    assoc_options[name] = association

  end

  def has_many(name, options = {})
    define_method("#{name}") do
      association = HasManyOptions.new(name.to_s, self.class.to_s, options)
      foreign_key_value = send(association.primary_key)
      result = association.model_class.send(:where, ({association.foreign_key => foreign_key_value}))
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  attr_accessor :assoc_options
  
  extend Associatable
end
