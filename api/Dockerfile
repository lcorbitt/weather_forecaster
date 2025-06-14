# Use the official Ruby image as a parent image
FROM ruby:3.2.2-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Make entrypoint script executable
RUN chmod +x ./bin/docker-entrypoint

# Set environment for running the server
ENV RAILS_ENV=development BUNDLE_WITHOUT=test

# Set the entrypoint
ENTRYPOINT ["./bin/docker-entrypoint"]

# Start the application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
