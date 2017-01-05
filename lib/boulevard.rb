require_relative 'boulevard/compiler'
require_relative 'boulevard/crypt'
require_relative 'boulevard/version'

module Boulevard
  def self.package_file(file_name, **rest)
    package(Compiler::FileName.new(file_name), **rest)
  end

  def self.package_code(code, **rest)
    package(Compiler::Code.new(code), **rest)
  end

  def self.package(compilable, secret_key: nil, data: nil)
    crypt = Crypt.new(secret_key)

    code = Compiler.new.(Compiler::Data.new(data), compilable)

    crypt.package(code)
  end

  def self.unpackage(package, secret_key: nil)
    Crypt.new(secret_key).unpackage(package)
  end
end
