require 'rspec/expectations'

RSpec::Matchers.define :have_code do |expected|
  def file_content(string)
    string.each_line.map(&:strip).reject(&:empty?).join("\n")
  end

  match do |actual|
    file_content(actual) == file_content(expected)
  end
end
