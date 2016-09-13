require 'test_helper'

class TrainerArticleTest < Minitest::Test
  def test_transform_returns_correct_json_transformation_for_supported_domains
    supported_domains = NewsScraper::Constants::SCRAPE_PATTERNS['domains'].keys

    supported_domains.each do |domain|
      raw_data = raw_data_fixture(domain)
      transformer = NewsScraper::Transformers::TrainerArticle.new(
        url: "#{domain}/some_article",
        payload: raw_data,
        scrape_details: NewsScraper::Constants::SCRAPE_PATTERNS['domains'][domain]
      )

      expected_transformation = transformation_fixture(domain)
      # Yaml has a hard time with new lines on a multi-line string
      expected_transformation.map { |_, v| v.strip! }

      assert_equal expected_transformation, transformer.transform
    end
  end
end