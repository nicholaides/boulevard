$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "boulevard"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = "spec/examples.txt"

  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random

  Kernel.srand config.seed
end


require 'rspec/expectations'

RSpec::Matchers.define :have_code do |expected|
  def file_content(string)
    string.each_line.map(&:strip).reject(&:empty?).join("\n")
  end

  match do |actual|
    file_content(actual) == file_content(expected)
  end
end

module RSpecIncludeHelpers
  def file(name, contents)
    File.join(@tmp_dir, name).tap do |path|
      FileUtils.mkdir_p File.dirname(path)
      File.write path, contents
    end
  end

  def code(str)
    Boulevard::Compiler::Code.new(str)
  end

  def file_name(name, contents)
    Boulevard::Compiler::FileName.new(file(name, contents))
  end

  def source_content_of(file_path, options={drop: 0})
    File.read(file_path).each_line.drop(options.fetch(:drop)).join
  end
end

module RSpecExtendHelpers
  def make_temporary_directory
    around do |example|
      Dir.mktmpdir do |dir|
        @tmp_dir = dir
        example.call
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpecIncludeHelpers
  config.extend RSpecExtendHelpers
end
