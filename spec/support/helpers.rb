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
