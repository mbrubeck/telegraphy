#!/usr/bin/env ruby
require 'sinatra'
require 'rugged'
include Rugged

$git_dir = 'data/workdir'
$repo = Repository.new($git_dir)

get %r{/(.*)} do |path|
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
<html><head>
  <title><%= @path %> (Telegraphy)</title>
</head><body>
  <h1><%= @path %></h1>
  <ul><% @tree.each {|o| %>
    <li><a href="<%= File.join('/',@path,o[:name]) %>">
      <%= o[:name] %>
    </a></li>
    <% } %>
    <li><form method="post">
      + <input name="name" type="text" placeholder="New file name" /> 
      <button type="submit">Create</button>
    </form></li></ul>
</body></html>

@@ file
<!DOCTYPE html>
<html><head>
  <title><%= @path %> (Telegraphy)</title>
</head><body>
  <h1><%= @path %></h1>
  <form method="post">
    <p><textarea name="data" rows="24" cols="80"><%= @f.content %></textarea>
    <p><input type="submit" value="Save">
  </form>
</body></html>
