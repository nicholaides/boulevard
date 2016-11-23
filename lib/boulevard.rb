require_relative 'boulevard/compiler'
require_relative 'boulevard/crypt'
require_relative 'boulevard/version'

module Boulevard
  def self.gem_file_path(rel_path)
    File.join(File.expand_path('../..', __FILE__), rel_path)
  end

  def self.compile_host_code(secret_key, host_type)
    Compiler.new.(
      Compiler::FileName.new(gem_file_path("lib/boulevard/host.rb")),
      Compiler::RuntimeSet.new(:secret_key, secret_key),
      Compiler::FileName.new(gem_file_path("lib/host_adapters/#{host_type}.rb")),
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

  def self.host_types
    Dir[File.expand_path('../host_adapters/*.rb', __FILE__)].map do |path|
      File.basename(path, '.rb')
    end
  end
end
