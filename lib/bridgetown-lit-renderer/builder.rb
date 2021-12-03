# frozen_string_literal: true

require "random-port"

module BridgetownLitRenderer
  module Renderer
    @serverpid = nil
    @serverport = nil

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
        entry_import = "import #{entry.to_json}"
        build_code = <<~JS
          import { Readable } from "stream"
          import { render } from "@lit-labs/ssr/lib/render-with-global-dom-shim.js"
          import { html } from "lit"
          #{entry_import}

          const ssrResult = render(html`
            #{code}
          `);

          let ret = []
          for (const chunk of ssrResult) {
            ret.push(chunk)
          }

          ret.join("")
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

      start_node_server

      output = Faraday.post(
        "http://localhost:#{@serverport}",
        "const data = #{data.to_json}; #{built_snippet}"
      ).body

      if output == "SCRIPT NOT VALID!"
        output = "<!-- SCRIPT ERROR: #{entry} -->"
        cache.delete(cache_key) if caching
      end

      output.html_safe
    end

    def self.start_node_server
      return if @serverpid

      @serverport = RandomPort::Pool.new.acquire
      node_file = File.expand_path("../../../src/serv.js", __FILE__)

      @serverpid = spawn(
        {"LIT_SSR_SERVER_PORT" => @serverport.to_s},
        "node #{node_file}",
        :pgroup => true
      )
      Process.detach @serverpid
      sleep 0.5
    end

    def self.stop_node_server
      if @serverpid
        Process.kill("SIGTERM", -Process.getpgid(@serverpid))
        @serverpid = nil
        @serverport = nil
      end
    end
  end

  class Builder < Bridgetown::Builder
    def build
      BridgetownLitRenderer::Renderer.reset
      hook :site, :post_render do
        BridgetownLitRenderer::Renderer.stop_node_server
      end

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
