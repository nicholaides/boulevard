# Boulevard: Backend-as-a-Parameter

Send the code you want to run as a parameter of your HTTP request.

Yes, it's a crazy idea.
And yes, it works.

## How does it work?

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
  Locally development, staging and production are always in sync with the back-end code.

### How does it run the code?
Your server `eval`s the code you send.

### What's to stop someone from changing my code or sending arbitrary code?
The code is signed (and encrypted) with a shared secret.
Any code that is not correctly signed with the shared secret is not run.

### What's to stop the user from looking at the code?
The code is encrypted (and signed) with a shared secret.

### Can the server run *any* code?
Right now, it only runs Ruby 1.9.3 (a limitation of Hook.io), but yes, it can run any code.

### What about dependencies?
At the moment, you'll have to stick to Ruby's standard library, which thankfully is rather robust.

### Do I need my own server?
Not needing your own server is kind of the point.
Right now, you can set up a free endpoint on Hook.io.

### What do I do about passwords, API Keys, and other things that I don't want to be public?
Those are encrypted, too, so nobody can see them.

## Demo (run from the shell)

1. Install Boulevard: `gem install boulevard` (or better yet, put it in your `Gemfile`).
2. Generate a secret key and save it.

        $ key=$(boulevard generate-key)

3. Set up a host to run your code.

    1. Generate the code that will run on your host.
      This is the code that receives your encrypted code and evals it.

            $ boulevard generate-host-code --secret-key "$key" --host-type hook_io | pbcopy

    2. Sign up for a free [Hook.io](https://hook.io) account (the only host currently supported).
      Create a "service" and set the type to Ruby, and paste the output from the `generate-host-code` you just ran command into the text box.

    3. Remember the URL of the service you just created.
      For this demo, we'll assign it to an environment variable.

            $ host='https://hook.io/nicholaides/blvd-test'

4. Write some back-end code.
  Save it in a file, like `my-hook.rb`

    ```ruby
    puts "Hello world"
    puts Hook['params'].inspect
    ```

5. Package up your back-end code.
  For this demo we'll store it in an environment variable.

        $ package=$(boulevard package-code --secret-key "$key" my-hook.rb)

6. Use Ajax, a form, or `curl` to send your code as a parameter:

        $ curl \
          -F "__code_package__=$package" \
          -F other-param=some_values \
          $host

        Hello world
        {"__code_package__"=>"BAh7CEkiDmVuY...", "other-param"=>"some_values"}
