SimpleForm.browser_validations = false

inputs = %w[
  CollectionSelectInput
  DateTimeInput
  FileInput
  GroupedCollectionSelectInput
  NumericInput
  PasswordInput
  RangeInput
  StringInput
  TextInput
]

module SimpleForm
  module Components

    module Icons
      def icon
        return icon_tag unless options[:icon].nil?
      end

      def icon_tag
        icon_tag = template.content_tag(:i, options[:icon][:content], class: options[:icon][:class], title: options[:icon][:title], data: options[:icon][:data] )
      end
    end

  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::Icons)

inputs.each do |input_type|
  superclass = "SimpleForm::Inputs::#{input_type}".constantize
 
  new_class = Class.new(superclass) do
    def input_html_classes
      super.push('text-field')
    end
  end
 
  Object.const_set(input_type, new_class)
end
 
# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.boolean_style = :nested
 
  config.button_class = 'btn btn-default'

  config.label_class = 'form-label'

  config.wrappers :bootstrap3, tag: 'div', class: 'form-row', error_class: 'has-error', defaults: { input_html: { class: 'default_class' } } do |b|
    b.use :html5
    b.use :min_max
    b.use :maxlength
    b.use :placeholder
    
    b.optional :pattern
    b.optional :readonly
    b.optional :autocomplete
    b.optional :autofocus
    b.optional :autocapitalize
    b.optional :autocorrect
    
    b.use :label_input
    b.use :hint,  wrap_with: { tag: 'small', class: 'help-block' }
    b.use :error, wrap_with: { tag: 'p', class: 'help-block has-error' }
  end
 
  config.wrappers :prepend, tag: 'div', class: 'form-row', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :autocomplete
    b.wrapper tag: 'div', class: 'controls' do |input|
      input.wrapper tag: 'div', class: 'input-group' do |prepend|
        prepend.use :label , class: 'input-group-addon' ###Please note setting class here fro the label does not currently work (let me know if you know a workaround as this is the final hurdle)
        prepend.use :input
      end
      input.use :hint,  wrap_with: { tag: 'small', class: 'help-block' }
      input.use :error, wrap_with: { tag: 'p', class: 'help-block has-error' }
    end
  end
 
  config.wrappers :append, tag: 'div', class: 'form-row', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :autocomplete
    b.wrapper tag: 'div', class: 'controls' do |input|
      input.wrapper tag: 'div', class: 'input-group' do |prepend|
        prepend.use :input
    prepend.use :label , class: 'input-group-addon' ###Please note setting class here fro the label does not currently work (let me know if you know a workaround as this is the final hurdle)
      end
      input.use :hint,  wrap_with: { tag: 'small', class: 'help-block' }
      input.use :error, wrap_with: { tag: 'p', class: 'help-block has-error' }
    end
  end
 
  config.wrappers :checkbox, tag: :div, class: "checkbox", error_class: "has-error" do |b|
 
    # Form extensions
    b.use :html5
 
    # Form components
    b.wrapper tag: :label do |ba|
      ba.use :input
      ba.use :label_text
    end
 
    b.use :hint,  wrap_with: { tag: :small, class: "help-block" }
    b.use :error, wrap_with: { tag: :p, class: "help-block text-danger" }
  end

  config.wrappers :inline_checkbox, :tag => 'div', :class => 'form-row', :error_class => 'error' do |b|
    b.use :html5
    b.use :placeholder
    b.wrapper :tag => 'div', :class => 'controls' do |ba|
      ba.use :label_input, :wrap_with => { :class => 'checkbox inline' }
      ba.use :error, :wrap_with => { :tag => 'p', :class => 'help-inline' }
      ba.use :hint,  :wrap_with => { :tag => 'small', :class => 'help-block' }
    end
  end

  config.wrappers :inline_select, :tag => 'div', :class => 'controls', :id => '', :error_class => 'error' do |b|
    b.use :html5
    b.use :placeholder
    b.wrapper :tag => 'div', :class => 'select-wrap fancy-select fancy-select-sm' do |ba|
      ba.use :input
      ba.use :error, :wrap_with => { :tag => 'p', :class => 'help-inline' }
      ba.use :hint,  :wrap_with => { :tag => 'small', :class => 'help-block' }
    end
  end

  # config.wrappers :inline_select_dob, :tag => 'div', :class => 'controls', :error_class => 'error' do |b|
  #   b.use :html5
  #   #b.use :placeholder
  #   b.use :label
  #   b.wrapper :tag => 'span', :class => 'select-wrap fancy-select fancy-select-sm' do |ba|
  #     ba.use :input
  #     b.use :DateTimeInput, :wrap_with => { :tag => 'span', :class => 'fancy-select fancy-select-sm' }
  #     ba.use :error, :wrap_with => { :tag => 'p', :class => 'help-inline' }
  #     ba.use :hint,  :wrap_with => { :tag => 'small', :class => 'help-block' }
  #   end
  # end

  config.wrappers :fancy_select, :tag => 'div', :class => 'form-row', :error_class => 'error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label
    b.wrapper :tag => 'div', :class => 'controls select-wrap fancy-select fancy-select-lg' do |ba|
      ba.use :input
      ba.use :error, :wrap_with => { :tag => 'p', :class => 'help-inline' }
      ba.use :hint,  :wrap_with => { :tag => 'small', :class => 'help-block' }
    end
  end





  # Wrappers for forms and inputs using the Twitter Bootstrap toolkit.
  # Check the Bootstrap docs (http://getbootstrap.com/)
  # to learn about the different styles for forms and inputs,
  # buttons and other elements.
  config.default_wrapper = :bootstrap3
end