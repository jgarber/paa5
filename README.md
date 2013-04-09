Paa5
========================

This is a proof-of-concept to demonstrate the creation of a
Ruby application platform-as-a-service. The aim is to replicate Heroku
on cheap servers. Instead of paying Heroku for multiple web and worker dynos,
you can just run your own server with multiple apps running multiple web and
worker processes for about $5 per month.

Add and configure your app through the web interface, then git push to
the provided remote repository. Your app will automatically be deployed like
Heroku, but unlike Heroku, you have the ability to write to the
filesystem, SSH in, and install anything you like with additional chef
recipes!

When you outgrow `git push` as a deployment mechanism, you can copy the
default deploy.rb script to your app's config/ directory and customize
it to your heart's content. Paa5 uses mina, which works similarly to
capistrano but is extremely fast.

* Restarts are seamless because it sends Puma and Nginx a USR2 signal.
* Scale your processes with a Foreman formation (e.g. web=2,worker=3)
* Manage application configuration with environment variables like Heroku

________________________

License
