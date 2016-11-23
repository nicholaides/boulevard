require "spec_helper"

describe 'CLI', type: :aruba do
  it 'can round-trip it' do
    run 'boulevard generate-key'
    expect(last_command_started).to be_successfully_executed
    key = last_command_started.output.strip

    run "boulevard generate-host-code --secret-key '#{key}' --host-type local_script"
    expect(last_command_started).to be_successfully_executed
    local_script = last_command_started.output

    write_file 'script.rb', 'print "Hello World"'
    run "boulevard package-code --secret-key '#{key}' script.rb"
    expect(last_command_started).to be_successfully_executed
    package = last_command_started.output.strip

    write_file 'package', package
    run "boulevard unpackage-code --secret-key '#{key}' package"
    expect(last_command_started).to be_successfully_executed


    write_file 'local_script_runner.rb', local_script
    run "ruby local_script_runner.rb '#{package}'"
    expect(last_command_started).to have_output 'Hello World'
    expect(last_command_started).to be_successfully_executed
  end
end
