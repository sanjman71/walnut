class ActiveRecord::Base
  def self.serialized_hash(attr_name, prefs_and_defaults = {})
    serialize(attr_name, Hash)

    define_method(attr_name) do
      value = super # Get the current value of the serialized attribute by calling the model's attribute accessor. This should be the full Hash
      if value.is_a?(Hash)
        # If the Hash value is defined return it, merging the defaults with these results so the the model's values override the defaults
        value.merge!(prefs_and_defaults) {|k,o,n| o}
      else
        # If the value is not defined, initialize it and return the defaults
        send("#{attr_name}=", Hash.new).merge!(prefs_and_defaults) {|k,o,n| o}
      end
    end

    # For each preference defined in the list, create accessor methods for use in views such as form_for clauses
    prefs_and_defaults.each do |preference, default|
      method_declarations = <<END_OF_CODE
        def #{attr_name}_#{preference}
          self.#{attr_name}[:#{preference}]
        end
        def #{attr_name}_#{preference}=(value)
          self.#{attr_name}[:#{preference}] = value
        end
END_OF_CODE
      eval method_declarations
    end
    
  end

end