ENV['PATH'] = [
  File.expand_path('../../../tmp/aruba', __FILE__),
  File.expand_path('../../../exe', __FILE__),
  ENV['PATH']
].join(File::PATH_SEPARATOR)

require 'aruba/rspec'

module RSpecArubaHelpers
  def sh(str)
    run str
    expect(last_command_started).to be_successfully_executed
    last_command_started.output.strip
  end
end

RSpec.configure do |config|
  config.include RSpecArubaHelpers, type: :aruba
end
