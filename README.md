# Boulevard: Backend-as-a-Parameter

Send the code you want to run as a parameter of your HTTP request.

Yes, it's a crazy idea.
And yes, it works.

## How does it work?

1. Write a back-end as a Rack app that you want to run on the server.
1. Your back-end code is compressed, encrypted, signed, and encoded as base64.
2. Put this base64 blob in a hidden form input, a query parameter, or a JSON request parameter, along with your other parameters.
3. Your back-end code will run on the server and have access to the other parameters.

## FAQ

### Why would you do this?
Sometimes you don't want to maintain a back-end.
For instance, let's say you have a static site that would benefit from a little back-end functionality.
Your options:

1. Find an existing service that does exactly what you want, exactly the way you want it.
2. Switch your hosting to something that allows back-end code.
3. Make another service in another repo (probably) and deploy it somewhere else, like Heroku.
  Now you have have to coordinate 2 repos and make sure they deploy at the same time together.
  Pull your hair out trying to ensure staging is using the right version of your service if you make changes on both repos.
4. Use Boulevard.
  All your code stays in 1 repo.
  Local development, staging and production are always in sync with the back-end code.

### How does it run the code?
Your server `eval`s the code you send.

### What's to stop someone from changing my code or sending arbitrary code?
The code is signed (and encrypted) with a shared secret.
Any code that is not correctly signed with the shared secret is not run.

### What's to stop the user from looking at the code?
The code is encrypted (and signed) with a shared secret.

### Can the server run *any* code?
Right now, it only runs Ruby 2.4.0, but yes, it can run any code.

### What about dependencies?
At the moment, you'll have to stick to Ruby's standard library, which thankfully is rather robust.

### Do I need my own server?
Not needing your own server is kind of the point.
Right now, you can set up a free endpoint on Hook.io.

### What do I do about passwords, API Keys, and other things that I don't want to be public?
Those are encrypted, too, so nobody can see them.

### If the code is being `eval`'d, what if it redefines constants/classes/modules on the server?

Feel free to define methods, classes, modules, and other constants because Boulevard uses a few tricks to keep your method/class/module definitions from sticking around after the request is over, but just like normal back-end code, you should avoid modifying global state.

## Demo (run from the shell)

1. Setup. You'll only have to do this the first time.
    1. Install Boulevard: `gem install boulevard` (or better yet, put it in your `Gemfile`).
    2. Generate a secret key.

            $ boulevard generate-key > .boulevard.key
            $ secret_key=$(cat .boulevard.key)

    3. Set up a Boulevard host on Heroku to run your code.
      You'll need Heroku's CLI tool and a Heroku account.
      Switch to a different directory and run:

            $ cd ~/Desktop
            $ git clone https://github.com/promptworks/boulevard-heroku-ruby
            $ cd boulevard-heroku-ruby
            $ heroku apps:create
            $ heroku config:set BOULEVARD_SECRET_KEY="$secret_key"
            $ git push heroku master

        Remember the URL of the Heroku app you just created.

            $ host='https://scrumptious-eagle.herokuapp.com'

2. Back in our app's directory, write a Rack app that will run on the back-end.
  Save it in a file, like `my-rack-app.rb`

    ```ruby
    lambda do |env|
      body = "Hello, " + env['boulevard.params']['first-name']

      [200, {'Content-Type' => 'text/plain'}, [body]]
    end
    ```

3. Use Ajax, a form, or `curl` to send your code (packaged up) as a parameter:

        $ package=$(boulevard package-code my-rack-app.rb)
        $ curl                            \
          -F "__code_package__=$package"  \
          -F first-name=Harambe           \
          $host

        Hello, Harambe

## Usage

### Secret keys

Whether you are using the CLI or Ruby library if you don't specify a secret key for a command, Boulevard will look for an read a `.boulevard.key` file in the current directory.

### Packaging code

When packaging up code, Boulevard will parse you `require_relative` statements and include those files as well.
It works recursively.

### Command Line

The command line tool is for shell scripting.
With it, you can do almost anything you can with the Ruby library.
Install the gem and run `boulevard --help` for more details.

### Ruby library

Mostly, you'll probably just want to package up some code to be sent.

If you have the code as a string:

```ruby
Boulevard.package_code(rack_app_as_a_string, secret_key:, env:)
```

If you have the code as a file:

```ruby
Boulevard.package_file(file_path_to_rack_app, secret_key:, env:)
```

#### `secret_key`
Your secret key as a string.
If this is `nil`, it will look for a `.boulevard.key` file.

#### `env`
Whatever you put in here will be Marshalled and accessible to your rack app as `env['boulevard.environment']`
This is useful for sending parameters that differ based on environment (dev/staging/prod).

E.g.

```ruby
bldv_env = if development?
             { our_email: 'testing-email@mailinator.com' }
           else
             { our_email: 'admin@mycompany.com' }
           end

Boulevard.package_file('blvd/contact_form.rb', env: bldv_env)
```
