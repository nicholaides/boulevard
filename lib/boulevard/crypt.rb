require 'openssl'
require 'base64'
require 'zlib'

module Boulevard
  class Crypt
    class NoKeyError < StandardError
    end

    KEY_FILE = '.boulevard.key'
    AUTH_DATA = ''

    def self.generate_key
      encode_key(build_cipher.random_key)
    end

    def self.build_cipher
      OpenSSL::Cipher.new('aes-256-gcm')
    end

    def self.encode_key(key)
      Base64.strict_encode64(key)
    end

    def self.decode_key(key)
      Base64.strict_decode64(key)
    end

    def initialize(key = nil)
      key ||= load_key_from_file or raise NoKeyError

      @key = self.class.decode_key(key)
    end

    def load_key_from_file
      File.read(KEY_FILE).strip if File.exists?(KEY_FILE)
    end

    def package(data)
      encrypted, iv, auth_tag = encrypt(self.class.zip(data))

      self.class.encode_envelope(
        'encrypted' => encrypted,
        'iv' => iv,
        'auth_tag' => auth_tag,
      )
    end

    def encrypt(data)
      cipher = self.class.build_cipher
      cipher.encrypt
      cipher.key = @key
      iv = cipher.random_iv
      cipher.auth_data = AUTH_DATA

      encrypted = cipher.update(data) + cipher.final
      auth_tag = cipher.auth_tag

      [encrypted, iv, auth_tag]
    end

    def unpackage(envelope)
      data = self.class.decode_envelope(envelope.strip)

      encrypted = data.fetch('encrypted')

      self.class.unzip(decrypt(encrypted, data.fetch('iv'), data.fetch('auth_tag')))
    end

    def decrypt(encrypted, iv, auth_tag)
      decipher = self.class.build_cipher
      decipher.decrypt
      decipher.key = @key
      decipher.iv = iv
      decipher.auth_tag = auth_tag
      decipher.auth_data = AUTH_DATA

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
