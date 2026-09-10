class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  %i[text_field email_field password_field file_field].each do |field_type|
    define_method(field_type) do |method, options = {}|
      component = field_type == :file_field ? "file-input" : "input"
      @template.safe_join([
        super(method, field_options(method, options, component, "w-full")),
        field_errors(method)
      ])
    end
  end

  def radio_button(method, tag_value, options = {})
    super(method, tag_value, field_options(method, options, "radio"))
  end

  # Radio groups render their errors once, below all options.
  def field_errors(method)
    messages = object.errors.full_messages_for(method).map { |message| @template.tag.p(message) }
    @template.tag.div(
      @template.safe_join(messages),
      id: @template.dom_id(object, "#{method}_errors"),
      class: "mt-2 text-sm text-error",
      aria: { live: "polite" }
    )
  end

  private
    def field_options(method, options, component, width = nil)
      invalid = object.errors[method].any?
      aria = options.fetch(:aria, {})
      error_id = @template.dom_id(object, "#{method}_errors")

      options.merge(
        class: @template.class_names(component, width, options[:class], "#{component}-error" => invalid),
        aria: aria.merge(
          invalid: invalid,
          describedby: [ aria[:describedby], error_id ].compact.join(" ")
        )
      )
    end
end
