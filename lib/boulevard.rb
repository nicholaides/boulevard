require_relative 'boulevard/compiler'
require_relative 'boulevard/crypt'
require_relative 'boulevard/version'

module Boulevard
  def self.compile_host_code(secret_key)
    Compiler.new.(
      Compiler::Code.new("$secret_key = #{secret_key.inspect}"),
      Compiler::FileName.new("lib/host_adapters/hook_io.rb")
    )
  end

  def self.package_file(secret_key, file_name)
    package(secret_key, Compiler::FileName.new(file_name))
  end

  def self.package_code(secret_key, code)
    package(secret_key, Compiler::Code.new(code))
  end

  def self.package(secret_key, compilable)
    Crypt.new(secret_key).package(Compiler.new.(compilable))
  end

  def self.unpackage(secret_key, package)
    Crypt.new(secret_key).unpackage(package)
  end
end
