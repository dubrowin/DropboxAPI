# DropboxAPI
Bash based DropboxAPI libraries for bash lambda layer

I use this to access my Dropbox account from Bash Lambdas (https://github.com/gkrizek/bash-lambda-layer). The Developer Key is stored in Parameter Store (it's cheaper than Secrets Manager and I don't need the key rotation).

* I tried to get this to work as a Lambda Layer, but ran into problems
* So I currently copy this from an S3 bucket and source it to get the functions and then use them.

