# frozen_string_literal: true

module BridgetownLitRenderer
  module Renderer
    def self.cache
      @cache ||= Bridgetown::Cache.new("LitSSR")
    end

    def self.reset
      @esbuild_notice_printed = false
      @render_notice_printed = false
    end

    def self.esbuild(code, site)
      unless @esbuild_notice_printed
        Bridgetown.logger.info "Lit SSR:", "Bundling with esbuild..."
        @esbuild_notice_printed = true
      end

      IO.popen(["node", site.in_root_dir("./config/lit-ssr.config.js")], "r+") do |pipe|
        pipe.puts({ code: code }.to_json)
        pipe.close_write
        pipe.read
      end
    end

    def self.render(code, data:, entry:, site:, caching: true) # rubocop:disable Metrics/MethodLength
      cache_key = "esbuild-#{code}#{entry}"
      built_snippet = nil

      builder = -> {
        build_code = <<~JS
          import { Readable } from "stream"
          import { render } from "@lit-labs/ssr/lib/render-with-global-dom-shim.js"
          import { html } from "lit"
          import #{entry.to_json}

          const ssrResult = render(html`
            #{code}
          `);

          const _tmplStream = Readable.from(ssrResult)

          let _tmplOutput = ""
          _tmplStream.on('data', function(chunk) {
            _tmplOutput += chunk;
          });

          _tmplStream.on('end',function() {
            process.stdout.write("====== SSR ======") // marker to ensure stray console outputs don't end up in HTML
            process.stdout.write(_tmplOutput)
          });
        JS

        esbuild(build_code, site)
      }


      built_snippet = if caching
                        cache.getset(cache_key) { builder.() }
                      else
                        builder.()
                      end

      unless @render_notice_printed
        Bridgetown.logger.info "Lit SSR:", "Rendering components..."
        @render_notice_printed = true
      end

      IO.popen(["node"], "r+") do |pipe|
        pipe.puts "const data = #{data.to_json}; #{built_snippet}"
        pipe.close_write
        pipe.read
      end.partition("====== SSR ======").last.html_safe
    end
  end

  class Builder < Bridgetown::Builder
    def build
      BridgetownLitRenderer::Renderer.reset
      helper "lit", helpers_scope: true do |
        data: {},
        hydrate_root: true,
        entry: "./frontend/javascript/lit-components.js",
        &block
      |
        code = view.capture(&block)
        if hydrate_root
          code = "<hydrate-root>#{code.sub(%r{\<([a-zA-Z]+-[a-zA-Z-]*)}, "<\\1 defer-hydration")}</hydrate-root>" # rubocop:disable Layout/LineLength
        end

        if site.config.disable_lit_caching
          next BridgetownLitRenderer::Renderer.render(code, data: data, entry: entry, site: site, caching: false)
        end

        entry_key = entry.start_with?("./") ? File.stat(site.in_root_dir(entry)).mtime : entry
        BridgetownLitRenderer::Renderer.cache.getset("output-#{code}#{data}#{entry_key}") do
          BridgetownLitRenderer::Renderer.render(code, data: data, entry: entry, site: site)
        end
      end
    end
  end
end

BridgetownLitRenderer::Builder.register
