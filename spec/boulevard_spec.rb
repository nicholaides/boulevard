require "spec_helper"

describe Boulevard do
  it "has a version number" do
    expect(Boulevard::VERSION).not_to be nil
  end

  describe 'packaging and unpackaging' do
    let(:secret_key) { Boulevard::Crypt.generate_key }
    let(:code) { Base64.encode64(Random.new.bytes(rand(2**12) + 1)) }
    let(:unpackaged) { Boulevard.unpackage(secret_key, package) }

    describe 'with code' do
      let(:package) { Boulevard.package_code(secret_key, code) }

      it 'should round-trip it' do
        expect(unpackaged).to include code
      end
    end

    describe 'with a file' do
      make_temporary_directory

      let(:path) { file('something.rb', code) }

      let(:package) { Boulevard.package_file(secret_key, path) }

      it 'should round-trip it' do
        expect(unpackaged).to include code
      end
    end
  end

  describe 'running the code' do
    let(:secret_key) { Boulevard::Crypt.generate_key }

    let(:script) do
      'print BoulevardRuntime.env[:message].reverse'
    end

    context 'localy', type: :aruba do
      before do
        write_file 'local_script_runner', Boulevard.compile_host_code(secret_key, :local_script)
      end

      context 'from a file' do
        let(:code_package) do
          write_file 'script.rb', script

          Boulevard.package_file(secret_key, 'tmp/aruba/script.rb', message: 'hello world')
        end

        it 'runs' do
          run "ruby local_script_runner '#{code_package}'"

          expect(last_command_started).to have_output 'hello world'.reverse
          expect(last_command_started).to be_successfully_executed
        end
      end

      context 'from a string' do
        let(:code_package) do
          Boulevard.package_code(secret_key, script, message: 'hello world')
        end

        it 'runs' do
          run "ruby local_script_runner '#{code_package}'"

          expect(last_command_started).to have_output 'hello world'.reverse
          expect(last_command_started).to be_successfully_executed
        end
      end
    end
  end
end
