# frozen_string_literal: true

module BridgetownLitRenderer
  class Builder < Bridgetown::Builder
    def build # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
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

      helper "lit", helpers_scope: true do |
        data: {},
        hydrate_root: true,
        entry: "./config/lit-components-entry.js",
        &block
      |
        code = view.capture(&block)
        if hydrate_root
          code = "<hydrate-root>#{code.sub(%r{<([a-zA-Z]+-[a-zA-Z-]*)}, "<\\1 defer-hydration")}</hydrate-root>" # rubocop:disable Layout/LineLength
        end

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

BridgetownLitRenderer::Builder.register
