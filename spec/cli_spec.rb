require 'rack/test'
require 'boulevard/host_app'
require 'json'

describe 'Using Boulevard from the CLI', type: :aruba do
  include Rack::Test::Methods
  let(:app) { Boulevard::HostApp.new(secret_key) }

  let(:secret_key) { sh 'boulevard generate-key' }

  let(:guest_app_code) do
    simple_rack_app "Rack::Request.new(env).params['some_param']"
  end

  it 'works end-to-end' do
    write_file 'guest-app.rb', guest_app_code

    package = sh "boulevard package-code --secret-key '#{secret_key}' guest-app.rb"
    write_file 'package.blvd', package

    expect {
      sh "boulevard unpackage-code --secret-key '#{secret_key}' package.blvd"
    }.to_not raise_exception

    post '/',
      some_param: 'Hello World',
      __code_package__: package

    expect(last_response.body).to eq 'Hello World'
  end
end
