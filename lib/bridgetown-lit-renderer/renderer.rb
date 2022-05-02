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

    def self.start_node_server(node_modules_path)
      return if serverpid

      self.authtoken =  SecureRandom.hex(64)
      self.serverport = RandomPort::Pool.new.acquire

      self.serverpid = spawn(
        {
          "LIT_SSR_SERVER_PORT" => serverport.to_s,
          "LIT_SSR_AUTH_TOKEN"  => authtoken,
          "NODE_PATH"           => node_modules_path,
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

      # TODO: shouldn't this use the sidecar Node process as well?
      IO.popen(["node", site.in_root_dir("./config/lit-ssr.config.js")], "r+") do |pipe|
        pipe.puts({ code: code }.to_json)
        pipe.close_write
        pipe.read
      end
    end

    def render(code, data:, entry:) # rubocop:todo Metrics/MethodLength
      raise "You must first assign the `site' accessor" unless site

      cache_key = "esbuild-#{code}#{entry}#{entry_key(entry)}"

      built_code = cache.getset(cache_key) { esbuild(js_code_block(entry, code)) }

      unless @render_notice_printed
        Bridgetown.logger.info "Lit SSR:", "Rendering components..."
        @render_notice_printed = true
      end

      self.class.start_node_server(site.in_root_dir("node_modules"))

      output = Faraday.post(
        "http://127.0.0.1:#{self.class.serverport}",
        "const data = #{data.to_json}; #{built_code}",
        "Authorization" => "Bearer #{self.class.authtoken}"
      ).body.force_encoding("utf-8")

      if output == "SCRIPT NOT VALID!"
        output = <<~HTML
          <ssr-error style="display:block; padding:0.3em 0.5em; color:white; background:maroon; font-weight:bold">
            Lit SSR error in #{entry}, see logs
          </ssr-error>
        HTML
        cache.delete(cache_key)
      end

      output.html_safe
    end

    def js_code_block(entry, code)
      entry_import = "import #{entry.to_json}"
      <<~JS
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
