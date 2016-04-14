#!/usr/bin/env ruby
require 'sinatra'
require 'rugged'
include Rugged

$git_dir = 'data/workdir'
$repo = Repository.new($git_dir)

def updateRepo()
  $repo.checkout('master')

  # fetch
  remote = $repo.remotes['origin']
  remote.fetch()

  # merge
  distant_commit = $repo.branches['origin/master'].target
  $repo.references.update($repo.head, distant_commit.oid)
end

get %r{/(.*)} do |path|
  updateRepo()

  @path = path
  begin
    @tree = $repo.lookup($repo.head.target_id).tree
  rescue ReferenceError
    @tree = []
  end

  if path.empty?
    erb :index
  else
    file = @tree.find { |f| f[:name] == path }
    redirect "/" if file.nil?

    @f = $repo.lookup(file[:oid])
    erb :file
  end
end

post %r{/(.*)} do |path|
  halt 405 if path.empty? and @request.params['name'].nil?
  updateRepo()
  path = @request.params['name'].nil? ? path : @request.params['name']

  content = @request.params['data'].nil? ? "" : @request.params['data'].gsub(/\r\n/, "\n")

  oid = $repo.write(content, :blob)
  index = $repo.index
  begin
    index.read_tree($repo.head.target.tree)
  rescue ReferenceError
  end
  index.add(:path => path, :oid => oid, :mode => 0100644)

  options = {}
  options[:tree] = index.write_tree($repo)

  options[:author] = { :email => "telegraphy@git.com", :name => 'Telegraphy', :time => Time.now }
  options[:committer] = { :email => "telegraphy@git.com", :name => 'Telegraphy', :time => Time.now }
  options[:message] ||= "Update #{path} from Telegraphy."
  options[:parents] = $repo.empty? ? [] : [ $repo.head.target ].compact
  options[:update_ref] = 'HEAD'

  Commit.create($repo, options)
  $repo.push 'origin', ['refs/heads/master']

  redirect "/#{path}"
end

__END__

@@ index
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

    <link href="http://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.97.6/css/materialize.min.css">

    <title>Telegraphy</title>
  </head>
  <body>
    <nav>
      <div class="nav-wrapper green lighten-1">
        <a href="/" class="brand-logo">&nbsp;Telegraphy</a>
        <ul class="right">
          <li>
            <a class="waves-effect waves-light modal-trigger" href="#newfile">
              <i class="material-icons">add</i>
            </a>
          </li>
        </ul>
      </div>
    </nav>

    <div class="container">
      <div id="newfile" class="modal bottom-sheet">
        <form method="post">
          <div class="modal-content">
            <h4 class="green-text text-lignten-1">New file on repository</h4>
            <div class="input-field">
              <input name="name" id="name" type="text" class="validate">
              <label for="name">New file name</label>
            </div>
          </div>
          <div class="modal-footer">
            <button id="nameBtn" type="submit" disabled class="disabled modal-action modal-close waves-effect waves-light btn green lighten-1 white-text">Create<i class="material-icons right">send</i></button>
          </div>
        </form>
      </div>

      <div class="collection"><% @tree.each {|o| %>
        <a href="<%= File.join('/',@path,o[:name]) %>" class="collection-item">
          <%= o[:name] %>
        </a>
        <% } %>
      </div>
    </div>
    
    <script type="text/javascript" src="https://code.jquery.com/jquery-2.1.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.97.6/js/materialize.min.js"></script>
    <script>
      $(document).ready(function() {
        $('.modal-trigger').leanModal();
        $('#name').on('input', function() {
          console.log($('#name').val());
          if ($(this).val() == "") {
            if (!$('#nameBtn').hasClass('disabled')) {
              $('#nameBtn').addClass('disabled');
              $('#nameBtn').attr('disabled', '');
            }
          } else {
            $('#nameBtn').removeClass('disabled');
            $('#nameBtn').removeAttr('disabled');
          }
        });
      });
    </script>
  </body>
</html>

@@ file
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

    <link href="http://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.97.6/css/materialize.min.css">

    <title><%= @path %> - Telegraphy</title>
  </head>
  <body>
    <nav>
      <div class="nav-wrapper green lighten-1">
        <a href="/" class="brand-logo">&nbsp;Telegraphy</a>
      </div>
    </nav>

    <div class="container">
      <div class="row">
        <div class="col s12">
          <div class="card hoverable">
            <form method="post">
              <div class="card-content">
                <span class="card-title"><%= @path %></span>
                <div class="input-field">
                  <textarea id="data" name="data" class="materialize-textarea"><%= @f.content %></textarea>
                  <label for="data">Content here</label>
                </div>
              </div>
              <div class="card-action">
                <button class="btn waves-effect waves-light green lighten-1" type="submit">Save<i class="material-icons right">send</i></button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
    
    <script type="text/javascript" src="https://code.jquery.com/jquery-2.1.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.97.6/js/materialize.min.js"></script>
  </body>
</html>

