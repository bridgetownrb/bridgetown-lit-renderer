# frozen_string_literal: true

require "random-port"
require "singleton"

module BridgetownLitRenderer
  class Renderer
    include Singleton

    class << self
      attr_accessor :serverpid, :serverport, :authtoken
    end

    attr_accessor :site

    def self.start_node_server
      return if serverpid

      self.authtoken =  SecureRandom.hex(64)
      self.serverport = RandomPort::Pool.new.acquire

      self.serverpid = spawn(
        {
          "LIT_SSR_SERVER_PORT" => serverport.to_s,
          "LIT_SSR_AUTH_TOKEN"  => authtoken,
        },
        "node #{File.expand_path("../../src/serve.js", __dir__)}",
        pgroup: true
      )
      Process.detach serverpid
      sleep 0.5
    end

    def self.stop_node_server
      return unless serverpid

      Process.kill("SIGTERM", -Process.getpgid(serverpid))
      self.serverpid = nil
      self.serverport = nil
    rescue Errno::ESRCH, Errno::EPERM, Errno::ECHILD # rubocop:disable Lint/SuppressedException
    end

    def entry_key(entry)
      entry.start_with?("./") ? File.stat(site.in_root_dir(entry)).mtime : entry
    end

    def reset
      @esbuild_notice_printed = false
      @render_notice_printed = false
    end

    def cache
      @cache ||= Bridgetown::Cache.new("LitSSR")
    end

    def esbuild(code)
      raise "You must first assign the `site' accessor" unless site

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

    def render(code, data:, entry:, caching: true) # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
      raise "You must first assign the `site' accessor" unless site

      cache_key = "esbuild-#{code}#{entry}#{entry_key(entry)}"

      esbuild_fn = -> { esbuild(js_code_block(entry, code)) }

      built_code = if caching
                     cache.getset(cache_key) { esbuild_fn.() }
                   else
                     esbuild_fn.()
                   end

      unless @render_notice_printed
        Bridgetown.logger.info "Lit SSR:", "Rendering components..."
        @render_notice_printed = true
      end

      self.class.start_node_server

      output = Faraday.post(
        "http://localhost:#{self.class.serverport}",
        "const data = #{data.to_json}; #{built_code}",
        "Authorization" => "Bearer #{self.class.authtoken}"
      ).body

      if output == "SCRIPT NOT VALID!"
        output = <<~HTML
          <ssr-error style="display:block; padding:0.3em 0.5em; color:white; background:maroon; font-weight:bold">
            Lit SSR error in #{entry}, see logs
          </ssr-error>
        HTML
        cache.delete(cache_key) if caching
      end

      output.html_safe
    end

    def js_code_block(entry, code)
      entry_import = "import #{entry.to_json}"
      <<~JS
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
    end
  end
end
