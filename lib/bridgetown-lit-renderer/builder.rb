# frozen_string_literal: true

module BridgetownLitRenderer
  class Builder < Bridgetown::Builder
    def build # rubocop:todo Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
      BridgetownLitRenderer::Renderer.instance.site = site
      BridgetownLitRenderer::Renderer.instance.reset

      hook :site, :post_read do
        BridgetownLitRenderer::Renderer.instance.cache.clear unless site.config.enable_lit_caching
      end

      hook :site, :post_render do
        BridgetownLitRenderer::Renderer.stop_node_server
      end

      hook :site, :server_shutdown do
        BridgetownLitRenderer::Renderer.stop_node_server
      end

      process_tag = ->(tag, attributes, code) do
        valid_tag = tag.to_s.tr("_", "-")
        segments = ["<#{valid_tag}"]
        attributes.each do |attr, _|
          attr = attr.to_s.tr("_", "-")
          segments << %( #{attr}="${data.#{attr}}")
        end
        segments << ">"
        segments << code
        segments << "</#{valid_tag}>"
        segments.join
      end

      jsonify_data = ->(data) do
        data.to_h do |k, v|
          processed_value = case v
                            when String
                              v
                            else
                              v.to_json
                            end
          [k, processed_value]
        end
      end

      helper "lit" do | # rubocop:todo Metrics/ParameterLists
        tag = nil,
        data: {},
        hydrate_root: true,
        entry: "./config/lit-components-entry.js",
        **kwargs,
        &block
      |
        code = block ? helpers.view.capture(&block) : ""
        code = process_tag.(tag, kwargs, code) if tag

        if hydrate_root
          code = "<hydrate-root>#{code.sub(%r{<([a-zA-Z]+-[a-zA-Z-]*)}, "<\\1 defer-hydration")}</hydrate-root>" # rubocop:disable Layout/LineLength
        end

        data = data.merge(kwargs)
        data = jsonify_data.(data)

        entry_key = BridgetownLitRenderer::Renderer.instance.entry_key(entry)
        BridgetownLitRenderer::Renderer.instance.cache.getset(
          "output-#{code}#{data}#{entry_key}"
        ) do
          BridgetownLitRenderer::Renderer.instance.render(
            code,
            data: data,
            entry: entry
          )
        end
      end
    end
  end
end
