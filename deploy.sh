#!/bin/bash
apt-get --assume-yes update
apt-get --assume-yes install git
repository="https://github.com/express42/reddit.git"
git clone "$repository"
git branch monolith
cd reddit
bundle install
puma -d
