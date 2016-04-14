#!/usr/bin/env ruby
require 'sinatra'
require 'slim'
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
    slim :index
  else
    file = @tree.find { |f| f[:name] == path }
    redirect "/" if file.nil?

    @f = $repo.lookup(file[:oid])
    slim :edit
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
