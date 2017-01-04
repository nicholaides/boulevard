describe Boulevard do
  it "has a version number" do
    expect(Boulevard::VERSION).not_to be nil
  end

  describe 'packaging and unpackaging' do
    let(:secret_key) { Boulevard::Crypt.generate_key }
    let(:code) { Base64.encode64(Random.new.bytes(rand(2**12) + 1)) }
    let(:unpackaged) { Boulevard.unpackage(package, secret_key: secret_key) }

    describe 'with code' do
      let(:package) { Boulevard.package_code(code, secret_key: secret_key) }

      it 'should round-trip it' do
        expect(unpackaged).to include code
      end
    end

    describe 'with a file' do
      make_temporary_directory

      let(:path) { file('something.rb', code) }

      let(:package) { Boulevard.package_file(path, secret_key: secret_key) }

      it 'should round-trip it' do
        expect(unpackaged).to include code
      end
    end
  end
end
