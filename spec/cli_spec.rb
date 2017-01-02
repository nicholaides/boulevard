require "spec_helper"

describe 'CLI', type: :aruba do
  it 'can round-trip it' do
    key = sh 'boulevard generate-key'

    write_file 'script.rb', 'print "Hello World"'

    write_file 'local_script_runner.rb',
      sh("boulevard generate-host-code --secret-key '#{key}' --host-type local_script")

    package = sh("boulevard package-code --secret-key '#{key}' script.rb")
    write_file 'package.blvd', package

    expect {
      sh "boulevard unpackage-code --secret-key '#{key}' package.blvd"
    }.to_not raise_exception

    expect(sh "ruby local_script_runner.rb '#{package}'").to eq 'Hello World'
  end
end
