#!/usr/bin/env ruby
require 'sinatra'
require 'grit'
include Grit

$git_dir = 'data/workdir'
$repo = Repo.new $git_dir

get %r{/(.*)} do |path|
  @path = path
  @o = path.empty? ? $repo.tree : $repo.tree/path
  erb (@o.is_a? Tree) ? :index : :file
end

post %r{/(.*)} do |path|
  o = $repo.tree/path
  halt 405 unless o.is_a? Blob
  filename = File.join($git_dir, path)
  open(filename, 'w') do |f|
    f << @request.params['data'].gsub(/\r\n/, "\n")
  end
  Dir.chdir $git_dir do
    $repo.add path
    $repo.commit_index "Update #{path} from Telegraphy."
  end
  redirect "/#{path}"
end

__END__

@@ index
<!DOCTYPE html>
<html><head>
  <title><%= @path %></title>
</head><body>
  <h1><%= @path %></h1>
  <ul><% @o.contents.each {|o| %>
    <li><a href="<%= File.join('/',@path,o.name) %>">
      <%= o.name %>
    </a></li>
  <% } %></ul>
</body></html>

@@ file
<!DOCTYPE html>
<html><head>
  <title><%= @path %></title>
</head><body>
  <h1><%= @path %></h1>
  <form method="post">
    <p><textarea name="data" rows="24" cols="80"><%= @o.data %></textarea>
    <p><input type="submit" value="Save">
  </form>
</body></html>
