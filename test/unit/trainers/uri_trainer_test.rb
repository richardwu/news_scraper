require 'test_helper'

module NewsScraper
  module Trainer
    class UriTrainerTest < Minitest::Test
      def setup
        super
        NewsScraper::Transformers::Article.any_instance.stubs(:transform)
        NewsScraper::Extractors::Article.any_instance.stubs(:extract)
      end

      def test_train_with_defined_scraper_pattern
        NewsScraper::Transformers::Article.any_instance.expects(:transform)
        NewsScraper::Extractors::Article.any_instance.expects(:extract)

        capture_subprocess_io do
          trainer = NewsScraper::Trainer::UriTrainer.new('google.ca')
          trainer.expects(:no_scrape_defined).never
          trainer.train
        end
      end

      def test_train_with_no_defined_scraper_pattern
        NewsScraper::Transformers::Article.any_instance.expects(:transform).raises(
          NewsScraper::Transformers::ScrapePatternNotDefined.new(root_domain: 'google.ca')
        )
        NewsScraper::Extractors::Article.any_instance.expects(:extract).returns('extract')

        capture_subprocess_io do
          trainer = NewsScraper::Trainer::UriTrainer.new('google.ca')
          trainer.expects(:no_scrape_defined).with('google.ca')
          trainer.train
        end
      end

      def test_no_scrape_defined_with_no_step_through
        NewsScraper::CLI.expects(:confirm).returns(false)
        NewsScraper::Trainer::PresetsSelector.any_instance.expects(:train).never

        capture_subprocess_io do
          trainer = NewsScraper::Trainer::UriTrainer.new('google.ca')
          trainer.expects(:save_selected_presets).never
          trainer.no_scrape_defined('google.ca')
        end
      end

      def test_no_scrape_defined_with_no_save
        NewsScraper::CLI.expects(:confirm).twice.returns(true, false)
        NewsScraper::Trainer::PresetsSelector.any_instance.expects(:train).returns({})

        capture_subprocess_io do
          trainer = NewsScraper::Trainer::UriTrainer.new('google.ca')
          trainer.expects(:save_selected_presets).never
          trainer.no_scrape_defined('google.ca')
        end
      end

      def test_no_scrape_defined_with_save
        NewsScraper::CLI.expects(:confirm).twice.returns(true, true)
        NewsScraper::Trainer::PresetsSelector.any_instance.expects(:train).returns('selected_presets' => 'selected_presets')

        capture_subprocess_io do
          trainer = NewsScraper::Trainer::UriTrainer.new('google.ca')
          trainer.expects(:save_selected_presets).with(
            'google.ca',
            'selected_presets' => 'selected_presets'
          )
          trainer.no_scrape_defined('google.ca')
        end
      end

      def test_save_selected_presets_saves_config
        presets = mock_presets
        domain_presets = write_domain_presets('totally-not-there.com', presets: presets)
        assert_equal presets, domain_presets
      end

      def test_save_selected_presets_overrides_the_config
        domain = 'totally-not-there.com'
        write_domain_presets(domain)

        presets = mock_presets('.pattern2')
        domain_presets = write_domain_presets(domain, presets: presets, overwrite_confirm: true)
        assert_equal presets, domain_presets
      end

      def test_save_selected_presets_saves_overwrite
        domain = NewsScraper::Constants::SCRAPE_PATTERNS['domains'].keys.first
        presets = mock_presets

        domain_presets = write_domain_presets(domain, presets: presets, overwrite_confirm: true)
        assert_equal presets, domain_presets
      end

      def test_save_selected_presets_no_overwrite
        domain = NewsScraper::Constants::SCRAPE_PATTERNS['domains'].keys.first
        original_presets = NewsScraper::Constants::SCRAPE_PATTERNS['domains'][domain]
        domain_presets = write_domain_presets(domain, overwrite_confirm: false)
        assert_equal original_presets, domain_presets
      end

      def write_domain_presets(domain, presets: mock_presets('.pattern'), overwrite_confirm: false)
        yaml_path = 'config/article_scrape_patterns.yml'
        NewsScraper::CLI.stubs(:confirm).returns(overwrite_confirm)

        Dir.mktmpdir do |dir|
          # Copy the yaml file to the tmp dir so we don't modify the main file in a test
          tmp_yaml_path = File.join(dir, yaml_path)
          FileUtils.mkpath(File.dirname(tmp_yaml_path))
          FileUtils.cp(yaml_path, tmp_yaml_path)

          # Chdir to the temp dir so we load the temp file
          Dir.chdir(dir) do
            capture_subprocess_io do
              trainer = NewsScraper::Trainer::UriTrainer.new('google.ca')
              trainer.save_selected_presets(domain, presets)
            end
            YAML.load_file(tmp_yaml_path)['domains'][domain]
          end
        end
      end

      def mock_presets(pattern = '.pattern')
        %w(body description keywords section time title).each_with_object({}) do |p, preset|
          preset[p] = { 'method' => 'css', 'pattern' => pattern }
        end
      end
    end
  end
end
