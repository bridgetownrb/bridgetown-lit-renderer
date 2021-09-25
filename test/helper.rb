# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "shoulda"
require "bridgetown"
require File.expand_path("../lib/bridgetown-lit-renderer", __dir__)

Bridgetown.logger.log_level = :error

Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(
    color: true
  ),
]

Minitest::Test.class_eval do # rubocop:disable Metrics/BlockLength
  ROOT_DIR = File.expand_path("fixtures", __dir__)
  SOURCE_DIR = File.join(ROOT_DIR, "src")
  DEST_DIR   = File.expand_path("dest", __dir__)

  def root_dir(*files)
    File.join(ROOT_DIR, *files)
  end

  def source_dir(*files)
    File.join(SOURCE_DIR, *files)
  end

  def dest_dir(*files)
    File.join(DEST_DIR, *files)
  end

  def with_metadata(data = {})
    FileUtils.mv(
      source_dir("_data/site_metadata.yml"),
      source_dir("_data/_site_metadata.yml")
    )
    File.write(
      source_dir("_data/site_metadata.yml"),
      data.transform_keys(&:to_s).to_yaml.sub("---\n", "")
    )

    yield

    FileUtils.rm(source_dir("_data/site_metadata.yml"))
    FileUtils.mv(
      source_dir("_data/_site_metadata.yml"),
      source_dir("_data/site_metadata.yml")
    )
  end

  def make_liquid_context(registers = {})
    Liquid::Context.new({}, {}, registers)
  end
end
