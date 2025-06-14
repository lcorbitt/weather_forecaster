# Weather Forecaster

A modern weather forecasting app that provides current temperature and conditions for any US address. Built with Ruby on Rails API and React frontend.

## Features

- Get current weather conditions by address
- View high/low temperatures
- 30-minute caching of weather data

## Tech Stack

**API:**
- Ruby on Rails 8.0
- PostgreSQL
- RSpec for testing
- Weather API integration

**Frontend:**
- React with TypeScript
- TanStack Query for data fetching
- Tailwind CSS for styling
- Google Maps integration

## Quick Start

1. Clone the repository:
```bash
git clone git@github.com:lcorbitt/weather_forecaster.git
cd weather_forecaster
```

2. Copy the example environment file and set your variables:
```bash
cp .env.example .env
```

3. Start the application using Docker:
```bash
docker compose up
```

The application will be available at:
- Frontend: http://localhost:5173
- API: http://localhost:3001

## Project Structure

```
weather_forecaster/
├── api/                # Rails API application
├── frontend/          # React frontend application
```

## Testing

The API includes comprehensive tests/specs:

**API Tests:**
```bash
docker compose exec api bundle exec rspec
```