ENV['PATH'] = [
  File.expand_path('../../../tmp/aruba', __FILE__),
  File.expand_path('../../../exe', __FILE__),
  ENV['PATH']
].join(File::PATH_SEPARATOR)

require 'aruba/rspec'
