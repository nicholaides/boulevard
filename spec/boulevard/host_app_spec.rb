require 'rack/test'
require 'json'

describe Boulevard::HostApp do
  include Rack::Test::Methods

  let(:key) { Boulevard::Crypt.generate_key }

  let(:code_package) { Boulevard::Crypt.new(key).package(guest_app_code) }

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
        %q%-> (env) { [ 200, { 'Content-Type' => 'text/plain' }, [Rack::Request.new(env).params['some-param']]] }%
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
        %q%-> (env) { [ 200, { 'Content-Type' => 'text/plain' }, [Rack::Request.new(env).params['some-param']]] }%
      end
    end
  end

  describe 'POST and JSON' do
    include_examples 'runs guest app' do
      let(:make_request) do
        post_json '/', 'some-param': 'some-value', '__code_package__': code_package
      end

      let(:guest_app_code) do
        %q%-> (env) { [ 200, { 'Content-Type' => 'text/plain' }, [JSON.parse(env['rack.input'].read)['some-param']]] }%
      end
    end
  end
end
