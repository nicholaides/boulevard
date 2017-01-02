require_relative 'crypt'

module BoulevardRuntime
end

module Boulevard
  module Host
    # TODO call this something else?
    def self.run(code_package)
      secret_key = BoulevardRuntime.secret_key
      code = Boulevard::Crypt.new(secret_key).unpackage(code_package)

      eval code
    end
  end
end

