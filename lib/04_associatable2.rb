require_relative '03_associatable'

# Phase IV
module Associatable

  def has_one_through(name, through_name, source_name)

    define_method("#{name}") do 

      through_options = self.class.assoc_options[through_name]
      # NOTE: self.class because this is not a class method.
      # through_options will return a BelongsToOption object
      foreign_key_value = send(through_options.foreign_key)

      source_options = through_options.model_class.assoc_options[source_name]
      # source_options will return a BelongsToOption object
      # BelongsToOptions objects between house and owner
      
      result = DBConnection.execute(<<-SQL)
        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
        JOIN
          #{source_options.table_name} 
          ON #{source_options.table_name}.#{source_options.primary_key} =
          #{through_options.table_name}.#{source_options.foreign_key}
        WHERE
          #{through_options.table_name}.#{through_options.primary_key} = #{foreign_key_value}
      SQL
      
      # SELECT houses.* FROM humans JOIN humans ON humans.id = houses.owner_id WHERE humans.id = ?
      # Trick was that both source_option's foreign and primary key were used in
      # SQL query.
      
      source_options.model_class.new(result.first)
    end
  end
end
