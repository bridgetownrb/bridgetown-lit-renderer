# frozen_string_literal: true

require_relative "./helper"

class TestBridgetownLitRenderer < Minitest::Test
  def setup
    Dir.chdir ROOT_DIR
    @site = Bridgetown::Site.new(Bridgetown.configuration(
                                   "root_dir"    => root_dir,
                                   "source"      => source_dir,
                                   "destination" => dest_dir,
                                   "quiet"       => true
                                 ))
  end

  context "sample plugin" do
    setup do
      @site.process
      @contents = File.read(dest_dir("index.html"))
    end

    should "output the Lit component" do
      assert_includes @contents, "<hydrate-root><happy-days"
      assert_includes @contents, "<p>Hello <!--lit-part-->there<!--/lit-part-->!"
      assert_includes @contents, "</template></happy-days></hydrate-root>"
    end
  end
end
