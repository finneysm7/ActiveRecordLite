require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]
    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]
      to_be_parsed = through_options.model_class
        .where({through_options.primary_key => self.send(through_options.foreign_key)}).first
      source_options.model_class
        .where({source_options.primary_key => to_be_parsed.send(source_options.foreign_key)}).first
    end
  end
end
