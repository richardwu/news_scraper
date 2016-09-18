require 'test_helper'

module NewsScraper
  class ConfigurationTest < Minitest::Test
    def test_raises_when_file_doesnt_exist
      assert_raises do
        Configuration.new(scrape_patterns_filepath: "nope")
      end
    end

    def test_scrape_patterns_loaded_from_filepath
      tmp_file = Tempfile.new
      tmp_file.write("domains:\n  test")
      tmp_file.rewind

      assert_equal({ 'domains' => 'test' }, Configuration.new(scrape_patterns_filepath: tmp_file.path).scrape_patterns)
    end
  end
end
