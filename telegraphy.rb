#!/usr/bin/env ruby
require 'sinatra'
require 'slim'
require 'rugged'
include Rugged

GIT_DIR = 'data/workdir'
REMOTE = 'origin'
BRANCH = 'master'
$repo = Repository.new(GIT_DIR)

def updateRepo()
  $repo.checkout(BRANCH)

  # fetch
  remote = $repo.remotes['' << REMOTE]
  remote.fetch()

  # merge
  distant_commit = $repo.branches['' << REMOTE << '/' << BRANCH].target
  $repo.references.update($repo.head, distant_commit.oid)
end

def createOptions(file)
  options = {}
  options[:tree] = index.write_tree($repo)

  options[:author] = { :email => "telegraphy@git.com", :name => 'Telegraphy', :time => Time.now }
  options[:committer] = { :email => "telegraphy@git.com", :name => 'Telegraphy', :time => Time.now }
  options[:message] ||= "Update #{file} from Telegraphy."
  options[:parents] = $repo.empty? ? [] : [ $repo.head.target ].compact
  options[:update_ref] = 'HEAD'
  return options
end

get %r{/(.*)} do |path|
  @path = path
  begin
    updateRepo()
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
  path = @request.params['name'].nil? ? path : @request.params['name']

  content = @request.params['data'].nil? ? "" : @request.params['data'].gsub(/\r\n/, "\n")

  oid = $repo.write(content, :blob)
  index = $repo.index
  begin
    updateRepo()
    index.read_tree($repo.head.target.tree)
  rescue ReferenceError
  end
  index.add(:path => path, :oid => oid, :mode => 0100644)

  Commit.create($repo, createOptions(path))
  $repo.push REMOTE, ['refs/heads/' << BRANCH]

  redirect "/#{path}"
end
