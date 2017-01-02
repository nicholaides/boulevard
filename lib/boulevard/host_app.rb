require 'rack'
require 'boulevard'

module Boulevard
  class HostApp < Struct.new(:key)
    class ExpandedRequest < Rack::Request
      def params(*)
        env['rack.request.json'] ||  super
      end

      def code_package
        params['__code_package__']
      end
    end

    def call(env)
      body = env['rack.input'].read
      env['rack.input'].rewind
      request = ExpandedRequest.new(env)

      if request.media_type == 'application/json' && !body.size.zero?
        env.update 'rack.request.json' => JSON.parse(body)
      end

      code_package = request.params.fetch('__code_package__')
      guest_app_script = Boulevard::Crypt.new(key).unpackage(code_package)

      # There's got to be a better way to isolate each run. How does ERB do it?
      isolated_scope = Class.new do
        @@guest_app_script = guest_app_script
        @@env = env

        class << self
          boulevard_environment = {}
          guest_app = eval(@@guest_app_script)
          @@env['boulevard.environment'] = boulevard_environment

          @@result = guest_app.call(@@env)

          def result
            @@result
          end
        end
      end

      isolated_scope.result
    end
  end
end
