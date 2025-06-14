# Use the official Ruby image as a parent image
FROM ruby:3.2.2-slim

# Set environment variables
ENV RAILS_ENV=${RAILS_ENV:-development} \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create and set the working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Configure the main process to run when running the image
CMD rm -f /app/tmp/pids/server.pid && \
    bundle exec rails db:prepare && \
    bundle exec rails server -b 0.0.0.0
