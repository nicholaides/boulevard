require "spec_helper"

describe Boulevard do
  it "has a version number" do
    expect(Boulevard::VERSION).not_to be nil
  end

  describe '.compile_host_code' do
    it 'generates code to be running on a server' do
      code = Boulevard.compile_host_code('my-secret-key')

      expect(code).to include 'my-secret-key'
      expect(code).to include source_content_of 'lib/boulevard/crypt.rb'
      expect(code).to include source_content_of 'lib/host_adapters/hook_io.rb', drop: 1
    end
  end

  describe 'packaging and unpackaging' do
    let(:secret_key) { Boulevard::Crypt.generate_key }
    let(:code) { Base64.encode64(Random.new.bytes(rand(2**12) + 1)) }
    let(:unpackaged) { Boulevard.unpackage(secret_key, package) }

    describe 'with code' do
      let(:package) { Boulevard.package_code(secret_key, code) }

      it 'should round-trip it' do
        expect(unpackaged).to eq code
      end
    end

    describe 'with a file' do
      make_temporary_directory

      let(:path) { file('something.rb', code) }

      let(:package) { Boulevard.package_file(secret_key, path) }

      it 'should round-trip it' do
        expect(unpackaged).to eq code
      end
    end
  end
end
