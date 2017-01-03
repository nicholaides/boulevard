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

Yeah, don't write code that messes with the global namespace.
Boulevard uses a few tricks to keep your method/class/module definitions from sticking around after the request is over, but just like normal back-end code, you should avoid modifying global state.

## Demo (run from the shell)

1. Setup. You'll only have to do this the first time.
    1. Install Boulevard: `gem install boulevard` (or better yet, put it in your `Gemfile`).
    2. Generate a secret key.

            $ boulevard generate-key > .boulevard.key
            $ secret_key=$(cat .boulevard.key)

    3. Set up a host on Heroku to run your code.

            $ git clone https://github.com/promptworks/boulevard-heroku-ruby
            $ cd boulevard-heroku-ruby
            $ heroku apps:create
            $ heroku config:set BOULEVARD_SECRET_KEY="$secret_key"
            $ git push heroku master

        Remember the URL of the Heroku you just created.

            $ host='https://scrumptious-eagle.herokuapp.com'

2. Write a Rack app that will run on the back-end.
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
