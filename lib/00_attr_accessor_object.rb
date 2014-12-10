class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) do #need to make it into two methods
        instance_variable_get("@#{name}") 
      end
      define_method("#{name}=") do |argument|
        instance_variable_set("@#{name}".to_sym, "#{argument}")
      end
    end
  end
end
