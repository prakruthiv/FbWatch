module Metrics
  module ModelHelper
    # in order to use this mixin, make sure the model has a field 'metric_class',
    # 'value' and 'name'
    def self.make_klass(class_name)
      options = {}
      yield options if block_given?

      class_name = class_name.camelize
      class_name = "Metrics::#{class_name}" if class_name.index('::').nil?
      class_name.constantize.new(options)
    end

    def klass
      if @klass.nil?
        @klass = ModelHelper.make_klass(self.metric_class) do |options|
          yield options if block_given?
        end
      end
      @klass
    end

    def vars_for_render
      if @vars_for_render.nil?
        custom_vars = klass.vars_for_render(value: self.value, name: self.name) if klass.class.method_defined? :vars_for_render

        @vars_for_render = {
          name: self.name,
          value: self.value
        }.merge(custom_vars || {})
      end

      @vars_for_render
    end

    def sort_value
      if klass.class.method_defined? :sort_value
        klass.sort_value(self.value)
      else
        self.value.to_s
      end
    end

    def empty?
      if klass.class.method_defined? :empty?
        klass.empty?(self.value)
      else
        self.value.blank?
      end
    end

    def view_name
      if klass.class.method_defined? :view_name
        klass.view_name(self.name)
      else
        self.name
      end
    end
  end
end