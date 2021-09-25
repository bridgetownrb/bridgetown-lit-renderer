# frozen_string_literal: true

require_relative "./helper"

class TestBridgetownLitRenderer < Minitest::Test
  def setup
    @site = Bridgetown::Site.new(Bridgetown.configuration(
                                   "root_dir"    => root_dir,
                                   "source"      => source_dir,
                                   "destination" => dest_dir,
                                   "quiet"       => true
                                 ))
  end

  context "sample plugin" do
    setup do
      with_metadata title: "My Awesome Site" do
        @site.process
        @contents = File.read(dest_dir("index.html"))
      end
    end

    should "output the overridden metadata" do
      assert_includes @contents, "<title>My Awesome Site</title>"
    end
  end
end
