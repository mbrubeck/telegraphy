Telegraphy
==========

Telegraphy is a web-based editor for text files in a git repository.

I keep all of my notes and to-do lists in plain text files, so I can edit and
search them with tools like vim, grep, and [todo.sh][1].  The files live in a
git repository, so I can edit them on any computer.  I wrote Telegraphy so
that I could view and edit my notes from my mobile phone, or from other
computers that don't have git installed.

Install
-------

Get the telegraphy source:

    git clone git://github.com/mbrubeck/telegraphy.git

Telegraphy depends on Sinatra and Grit.  You may also need to add several Grit
dependencies, if they aren't automatically installed:

    gem install sinatra grit
    gem install rcov hoe archive-tar-minitar nokogiri mime-types

Create the Telegraphy git repository:

    cd telegraphy
    ./init.sh

This creates two git repositories, `origin` and `workdir`.  They are linked
together using git hooks, so commits to either repository will be pushed
automatically to the other.  Telegraphy reads from and writes to `workdir`,
while `origin` is a bare repository for you to push and pull to.

Here's how to clone the empty Telegraphy repository and push your first commit
to it:

    git clone data/origin my-repository
    cd my-repository
    echo Hello >test.txt
    git commit -m "Initial commit."
    git push

Or you can push an existing git repository to the Telegraphy:

    cd /path/to/existing-repository
    git remote add telegraphy /path/to/telegraphy/data/origin
    git push telegraphy master

Run
---

Run `ruby -rubygems telegraphy.rb` to start the application, then go to
http://localhost:4567/ to view your files.  Click on a file name to view or
edit it.  Your changes will be committed automatically to the git repository,
and you can them pull them into any cloned repositories.

Deploy
------

To deploy Telegraphy to a Rack-enabled web server (e.g. Apache with
mod_passenger), create a Rackup file like this in the telegraphy directory:

    cat >config.ru <<EOF
    require 'rubygems'
    require 'telegraphy'
    run Sinatra::Application
    EOF

You can also use Rack middleware to add features like OpenID or password
authentication.  Check your server documentation and the [Sinatra Book][2] for
more Rack configuration instructions.

To do
-----

* Handle conflicts (if a change is pushed to the repository while you're
  editing a file).
* Creating new files through the web app.
* Better UI design.
* Integrate with todo.sh.

[1]: http://ginatrapani.github.com/todo.txt-cli/
[2]: http://www.sinatrarb.com/book.html
