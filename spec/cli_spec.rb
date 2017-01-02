require 'rack/test'
require 'boulevard/host_app'
require 'json'

describe 'CLI', type: :aruba do
  include Rack::Test::Methods
  attr_accessor :app

  def post_json(uri, json)
    post uri, json.to_json, "CONTENT_TYPE" => "application/json"
  end

  let(:guest_app_code) do
    %q%-> (env) { [ 200, { 'Content-Type' => 'text/plain' }, [Rack::Request.new(env).params['some-param']]] }%
  end

  it 'works end-to-end' do
    key = sh 'boulevard generate-key'

    write_file 'guest-app.rb', guest_app_code

    package = sh "boulevard package-code --secret-key '#{key}' guest-app.rb"
    write_file 'package.blvd', package

    expect {
      sh "boulevard unpackage-code --secret-key '#{key}' package.blvd"
    }.to_not raise_exception

    self.app = Boulevard::HostApp.new(key)

    post '/', 'some-param': 'Hello World', __code_package__: package

    expect(last_response.body).to eq 'Hello World'
  end
end
