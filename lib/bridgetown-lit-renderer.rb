# frozen_string_literal: true

require "bridgetown"
require "bridgetown-lit-renderer/renderer"
require "bridgetown-lit-renderer/builder"

Bridgetown.initializer :"bridgetown-lit-renderer" do |config|
  config.builder BridgetownLitRenderer::Builder
end
