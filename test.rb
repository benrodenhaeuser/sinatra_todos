class TheClass
  def my_method(&block)
    @a = 10
    instance_eval(&block)
  end
end

def my_method(&block)
  TheClass.new.send(:my_method, &block)
end

my_method { puts self } # #<TheClass:0x007ffc9b8230f8>
my_method { puts @a } # 10

# instance_eval documentation: Evaluates a string containing Ruby source code, or the given block, within the context of the receiver (obj). In order to set the context, the variable self is set to obj while the code is executing, giving the code access to obj’s instance variables and private methods.
