module ActionView
  class StreamingTemplateRenderer < TemplateRenderer
    
    def render_template(template, layout_name = nil, locals = {}) #:nodoc:
      return [super] unless layout_name && template.supports_streaming?

      locals ||= {}
      layout   = layout_name && find_layout(layout_name, locals.keys, [formats.first])

      Body.new do |buffer|
        if template.handler == Jstreamer::Handler
          delayed_render_json(buffer, template, layout, @view, locals)
        else
          delayed_render(buffer, template, layout, @view, locals)
        end
      end
    end

    private

      def delayed_render_json(buffer, template, layout, view, locals)
        # Wrap the given buffer in the StreamingBuffer and pass it to the
        # underlying template handler. Now, every time something is concatenated
        # to the buffer, it is not appended to an array, but streamed straight
        # to the client.
        output  = ActionView::JSONStreamingBuffer.new(buffer)
        yielder = lambda { |*name| view._layout_for(*name) }
      
        instrument(:template, identifier: template.identifier, layout: layout.try(:virtual_path)) do
          fiber = Fiber.new do
            template.render(view, locals, output, &yielder)
          end

          fiber.resume
        end

      end

  end
end