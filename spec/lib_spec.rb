require 'rack/test'
require 'boulevard/host_app'
require 'json'

describe 'Using Boulevard from Ruby' do
  include Rack::Test::Methods
  let(:app) { Boulevard::HostApp.new(secret_key) }

  let(:secret_key) { Boulevard::Crypt.generate_key }

  it 'works end-to-end' do
    guest_app_code = simple_rack_app "Rack::Request.new(env).params['some_param']"

    package = Boulevard.package_code(guest_app_code, secret_key: secret_key)

    post '/',
      some_param: 'Hello World',
      __code_package__: package

    expect(last_response.body).to eq 'Hello World'
  end

  it 'can include an environment' do
    guest_app_code = simple_rack_app "env['boulevard.environment'][:some_env_param]"
    package = Boulevard.package_code(
      guest_app_code,
      secret_key: secret_key,
      env: { some_env_param: 'Hello World' }
    )

    post '/', __code_package__: package

    expect(last_response.body).to eq 'Hello World'
  end
end

