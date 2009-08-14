class ActiveRecord::Base
  def self.typed_serialize(attr_name, class_name, *args)
    serialize(attr_name, class_name)

    define_method(attr_name) do
      expected_class = self.class.serialized_attributes[attr_name.to_s]
      if (value = super).is_a?(expected_class) 
        value
      else
        send("#{attr_name}=", expected_class.new)
      end
    end
    
    args.each do |method_name|
      method_declarations = <<END_OF_CODE
        def #{attr_name}_#{method_name}
          self.#{attr_name}[:#{method_name}]
        end
        def #{attr_name}_#{method_name}=(value)
          self.#{attr_name}[:#{method_name}] = value
        end
END_OF_CODE
      eval method_declarations
    end
    
  end

end