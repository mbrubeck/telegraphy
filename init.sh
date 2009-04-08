#!/bin/sh

APP_ROOT=$PWD
DATA_DIR=$APP_ROOT/data

# Directory structure for Rack deployment.
mkdir -p tmp public

# Set up the bare master repository.
mkdir -p $DATA_DIR/origin
cd $DATA_DIR/origin
git init --bare
ln -sf $APP_ROOT/hooks/origin-post-update hooks/post-update

# Set up the working repository.
mkdir -p $DATA_DIR/workdir
cd $DATA_DIR/workdir
git init
git remote add origin $DATA_DIR/origin
ln -sf $APP_ROOT/hooks/workdir-post-commit .git/hooks/post-commit
