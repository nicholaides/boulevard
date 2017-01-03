require 'rack/test'
require 'json'
require_relative '../../lib/boulevard/host_app'

describe Boulevard::HostApp do
  include Rack::Test::Methods

  let(:key) { Boulevard::Crypt.generate_key }

  let(:code_package) { package(guest_app_code) }
  let(:modal) { package(guest_app_code) }

  def package(*guest_app_code)
    Boulevard::Crypt.new(key).package(guest_app_code.join("\n"))
  end

  def expect_guest_app_to_run
    make_request

    expect(last_response.body).to eq 'some-value'
    expect(last_response.status).to eq 200
    expect(last_response.headers['Content-Type']).to eq 'text/plain'
  end

  shared_examples 'runs guest app' do
    describe description do
      describe '*sanity check*' do
        let(:app) { eval(guest_app_code) }
        it('runs') { expect_guest_app_to_run }
      end

      describe 'in Boulevard host app' do
        let(:app) { described_class.new(key) }
        it('runs') { expect_guest_app_to_run }
      end
    end
  end

  describe 'GET w query params' do
    include_examples 'runs guest app' do
      let(:guest_app_code) do
        simple_rack_app "
          Rack::Request.new(env).params['some-param']
        "
      end

      let(:make_request) do
        get "/?some-param=some-value&__code_package__=#{CGI::escape(code_package)}"
      end
    end
  end

  describe 'POST and form params' do
    include_examples 'runs guest app' do
      let(:make_request) do
        post '/', 'some-param': 'some-value', '__code_package__': code_package
      end

      let(:guest_app_code) do
        simple_rack_app "
          Rack::Request.new(env).params['some-param']
        "
      end
    end
  end

  describe 'POST and JSON' do
    include_examples 'runs guest app' do
      let(:make_request) do
        post_json '/', 'some-param': 'some-value', '__code_package__': code_package
      end

      let(:guest_app_code) do
        simple_rack_app "
          JSON.parse(env['rack.input'].read)['some-param']
        "
      end
    end
  end

  describe 'runtime' do
    let(:app) { described_class.new(key) }

    let(:definitions) do
      "
        def a_method; end
        def self.a_class_method; end
        a_local_var = true
        @a_ivar = true
        class AClass; end
        module AModule; end
      "
    end

    let(:rack_app_that_returns_definitions) do
      "
        definitions = {
          a_method: defined?(a_method),
          a_class_method: defined?(self.a_class_method),
          a_local_var: defined?(a_local_var),
          a_ivar: defined?(@a_ivar),
          AClass: defined?(AClass),
          AModule: defined?(AModule),
        }

        ->(*) { [200, {'Content-Type'=>'text/plain'}, definitions.to_json] }
      "
    end

    it 'can define methods and stuff' do
      post '/', '__code_package__': package(
        definitions,
        rack_app_that_returns_definitions
      )

      returned_definitions = JSON.parse(last_response.body)
      expect(returned_definitions).to all satisfy { |_key, value| value }
    end

    it 'does not leave methods and classes lying around after each request' do
      post '/', '__code_package__': package(definitions, simple_rack_app(''))

      post '/', '__code_package__': package(rack_app_that_returns_definitions)

      returned_definitions = JSON.parse(last_response.body)
      expect(returned_definitions).to all satisfy { |_key, value| !value }
    end
  end
end
