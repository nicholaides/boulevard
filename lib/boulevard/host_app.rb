require 'rack'
require 'rack/cors'
require 'boulevard'

module Boulevard
  module HostApp
    def self.new(key)
      Rack::Builder.new do
        use Rack::Cors do
          allow do
            origins '*'
            resource '*', headers: :any, methods: :any
          end
        end
        use Params
        run EvalPackage.new(key)
      end
    end
  end

  class Params < Struct.new(:app)
    def call(env)
      body = env['rack.input'].read
      env['rack.input'].rewind
      request = Rack::Request.new(env)

      if request.media_type == 'application/json' && !body.size.zero?
        env['rack.request.json'] = JSON.parse(body)
      end

      env['boulevard.params'] = env['rack.request.json'] || request.params
      env['boulevard.code_package'] = env.fetch('boulevard.params').fetch('__code_package__')

      app.call(env)
    end
  end

  class EvalPackage < Struct.new(:key)
    $boulevard_runs = {}

    def call(env)
      guest_app_script = Boulevard.unpackage(
        env.fetch('boulevard.code_package'),
        secret_key: key
      )

      # random name so that we can avoid collisions because we have to use
      # global state:
      # - defining a module
      # - global ariable $boulevard_runs
      run_name = "BLVD#{rand.to_s.sub('.', '')}"

      # we'll store the boulevard environment and rack app in here
      guest_run = {}

      # Assign it to a global so we can access it in the code below. Because
      # it's eval'ed in a module definition, it won't have access to this scope.
      $boulevard_runs[run_name] = guest_run

      eval "
        # - Wrap everything in a module definition so that constant definitions
        #   get attached to this module
        # - Use random module name so that multiple threads won't have
        #   colisions
        # - prefix with `::` to avoid collisions with this module's constants
        module ::#{run_name}

          # Run it all in an object instance so that `def` can work as
          # expected.  If run in a class/module body, `def`s would be instance
          # methods and not accessible.
          Object.new.instance_eval do

            # The contents of this variable will globally accessible via
            # $boulevard_runs
            guest = $boulevard_runs[#{run_name.inspect}]

            # this variable is overridden if there is any Compiler::Environment
            boulevard_environment = {}

            # - Wrap in begin/end so that the return value of the last line of
            #   the guest script is captured
            # - guest_run is
            guest[:app] = begin
              #{guest_app_script}
            end

            # save the environment in order to pass it in to the rack app
            guest[:environment] = boulevard_environment
          end

        end
      "

      # put it in the env so that the guest app can have access to it
      env['boulevard.environment'] = guest_run[:environment]

      # Remove these so they can be garbage collected. Otherwise, every request
      # would add something to memory that would never get garbage collected.
      Object.send :remove_const, run_name
      $boulevard_runs.delete(run_name)

      guest_run[:app].call(env)
    end
  end
end
