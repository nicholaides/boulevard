require 'openssl'
require 'base64'
require 'zlib'

module Boulevard
  class Crypt
    class SignatureError < StandardError
    end

    def self.generate_key
      encode_key(build_cipher.random_key)
    end

    def self.build_cipher(args = ['aes-256-cbc'])
      OpenSSL::Cipher.new(*args)
    end

    def self.encode_key(key)
      Base64.strict_encode64(key)
    end

    def self.decode_key(key)
      Base64.strict_decode64(key)
    end

    def initialize(key)
      @key = self.class.decode_key(key)
    end

    def sign(data)
      OpenSSL::HMAC.digest('SHA256', @key, data)
    end

    def package(data)
      encrypted, iv = encrypt(self.class.zip(data))

      self.class.encode_envelope(
        'encrypted' => encrypted,
        'iv' => iv,
        'signature' => sign(encrypted),
      )
    end

    def encrypt(data)
      cipher = self.class.build_cipher
      cipher.encrypt
      cipher.key = @key
      iv = cipher.random_iv

      encrypted = cipher.update(data) + cipher.final

      [encrypted, iv]
    end

    def unpackage(envelope)
      data = self.class.decode_envelope(envelope)

      encrypted = data.fetch('encrypted')

      verify_signature! encrypted, data.fetch('signature')

      self.class.unzip(decrypt(encrypted, data.fetch('iv')))
    end

    def verify_signature!(encrypted, signature)
      raise SignatureError if sign(encrypted) != signature
    end

    def decrypt(encrypted, iv)
      decipher = self.class.build_cipher
      decipher.decrypt
      decipher.key = @key
      decipher.iv = iv

      decipher.update(encrypted) + decipher.final
    end

    def self.zip(data)
      Zlib.deflate(data, 9)
    end

    def self.unzip(data)
      Zlib.inflate(data)
    end

    def self.dump(native)
      Marshal.dump(native)
    end

    def self.load(serialized)
      Marshal.load(serialized)
    end

    def self.encode_envelope(native_object)
      str = dump(native_object)
      Base64.strict_encode64(str)
    end

    def self.decode_envelope(base64)
      serialized = Base64.strict_decode64(base64)
      load(serialized)
    end
  end
end
