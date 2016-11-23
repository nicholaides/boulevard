require_relative 'boulevard/compiler'
require_relative 'boulevard/crypt'
require_relative 'boulevard/version'

module Boulevard
  def self.compile_host_code(secret_key, host_type)
    Compiler.new.(
      Compiler::FileName.new("lib/boulevard/host.rb"),
      Compiler::RuntimeSet.new(:secret_key, secret_key),
      Compiler::FileName.new("lib/host_adapters/#{host_type}.rb"),
    )
  end

  def self.package_file(secret_key, file_name, env = nil)
    package(secret_key, Compiler::FileName.new(file_name), env)
  end

  def self.package_code(secret_key, code, env = nil)
    package(secret_key, Compiler::Code.new(code), env)
  end

  def self.package(secret_key, compilable, env = nil)
    crypt = Crypt.new(secret_key)

    code = Compiler.new.(
      Compiler::RuntimeSet.new(:env, env),
      compilable,
    )

    crypt.package(code)
  end

  def self.unpackage(secret_key, package)
    Crypt.new(secret_key).unpackage(package)
  end
end
