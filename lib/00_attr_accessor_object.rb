class AttrAccessorObject

  def self.my_attr_accessor(*names)

    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end

    names.each do |name|
      define_method("#{name}=") do |new_value|
        instance_variable_set("@#{name}", new_value)
      end
    end

  end

end


# class MyAttrAccessorObject < AttrAccessorObject
#   attr_accessor :x, :y
#
#   def x
#     @x
#   end
#
#   def x=(new_val)
#     @x = new_val
#   end
# end
