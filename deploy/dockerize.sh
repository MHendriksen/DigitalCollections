#!/bin/bash -ex

COMMIT=$1
RAILS_ENV=$2

RUBY_VERSION=$(git show master:.ruby-version)

git archive $COMMIT > tmp/kor.tar

sudo docker run --rm \
  -v $(pwd)/deploy/docker/Dockerfile.erb:/template.erb \
  ruby:$RUBY_VERSION \
  erb ruby_version=$RUBY_VERSION rails_env=$RAILS_ENV /template.erb \
  > tmp/kor.dockerfile

sudo docker build \
  --rm=true \
  --force-rm \
  -f tmp/kor.dockerfile \
  -t docker.coneda.net:443/kor:$COMMIT \
  .