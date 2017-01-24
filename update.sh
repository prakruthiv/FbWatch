#!/bin/bash

echo "# Fetching newest sources"
git pull

echo ""
echo "# Updating dependencies"
bundle install --deployment

echo ""
echo "# Precompiling assets"
RAILS_ENV=production bundle exec rake assets:precompile

echo ""
echo "# Migrating database"
RAILS_ENV=production bundle exec rake db:migrate

echo ""
echo "# Reloading app on next request"
touch tmp/restart.txt
