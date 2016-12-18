# Boulevard: Backend-as-a-Parameter

Send the code you want to run as a parameter *with* your request.
Yes, it's a crazy idea.
And yes, it works.

## How does it work?

1. When you are generating some client-side code, you use Boulevard to create a "package" which is your back-end code encrypted, signed, and encoded in base64.
2. Put the package in a hidden form input, a query parameter, or a JSON request parameter, along with your other parameters.
3. When you submit your form or AJAX, the code will run and have access to the other parameters.

## FAQ

### Why would you do this?
Sometimes, you don't want to maintain a back end.  For instance, let's say you have a static site that would benefit from a little back-end functionality. You options:

1. Find an existing service that does exactly what you want, exactly the way you want it.
2. Switch your hosting situation to something that allows you to build-in a back-end.
3. Make another service, in another repo (probably), and deploy it somewhere else, like Heroku.
  Now you have have to coordinate 2 deploys and keep them in sync when you make changes that affect both projects.
4. Use Boulevard. Deployment stays the same. No extra repos.

### How does it run the code?
Your server `eval`s the code you send.

### What's to stop someone from sending arbitrary code?
The code is signed with a shared secret. Any changes would break the signature. Only the secret key is capable of generating a valid signature.

### What's to stop the user from looking at the code?
The code is encrypted with a shared secret.

### Can the server run *any* code?
Right now, it only does Ruby, but yes, it can run any code. Because the code is signed with your secret key, you can trust that it's the code you want to run?

### Do I need my own server?
Not needing your own server is kind of the point. Right now, you can set up a free endpoint on Hook.io.

## Demo

1. Install Boulevard: `gem install boulevard` (or better yet, put it in your `Gemfile`).
2. Generate a secret key and save it.

        > key=$(boulevard generate-key)

3. Set up a host to run your code.

    1. Generate the code that will run on your host. This is the code that receives your encrypted code and evals it.

            > boulevard generate-host-code --secret-key "$key" --host-type hook_io | pbcopy

    2. The only host currently supported is Hook.io. Go there, sign in with your Github account, and create a "service", set the type to Ruby, and paste the output from the `generate-host-code` command into the text box.

    3. Remember the URL of the service you just cerated. You'll need it later.

            > host=https://hook.io/nicholaides/blvd-test

4. Write some back-end code. Save it in a file, like `my-hook.rb`

        puts "Hello world"
        puts Hook['params'].inspect

5. Package up your hook code:

    > package=`boulevard package-code --secret-key "$key" my-hook.rb`

6. Use Ajax, a form, or `curl` to send your code as a parameter:

    > curl -F "__code_package__=$package" -F other-param=some_values $host

    Hello world
    {"__code_package__"=>"BAh7CEkiDmVuY...", "other-param"=>"some_values"}
