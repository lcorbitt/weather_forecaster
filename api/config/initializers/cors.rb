Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', 'http://localhost:5173')

    resource '*',
      headers: :any,
      methods: [:get, :options, :head],
      credentials: true
  end
end
