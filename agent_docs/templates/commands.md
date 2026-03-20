# Commands — [Project Name]

<!-- Fill in all [commands] before the first sprint. Keep this up to date. -->

## Backend

```bash
# Install dependencies
[command]

# Run dev server
[command]

# Run all tests
[command]

# Run tests with coverage (must hit 80% minimum)
[command]

# Build for production
[command]

# Run pending DB migrations
[command]

# Create a new migration
[command]

# Lint
[command]
```

## Frontend

```bash
# Install dependencies
npm install

# Run dev server
npm run dev

# Run unit tests
npm run test

# Run tests with coverage
npm run coverage

# Build for production
npm run build

# Lint
npm run lint

# Run E2E tests (headless)
npx playwright test

# Run E2E tests (headed, for debugging)
npx playwright test --headed
```

## Docker

```bash
# Start all services (local dev)
docker-compose up

# Rebuild and start
docker-compose up --build

# Start a specific service
docker-compose up [service-name]

# Stop all services
docker-compose down

# Tail logs for a service
docker-compose logs -f [service-name]

# Build production image
docker build -t [project]-[service]:latest -f [Service].Dockerfile .
```

## Database

```bash
# Connect to local DB
[command]

# Connect to staging DB (read-only)
[command]

# Seed local dev data
[command]

# Reset local DB (drops + remigrates + seeds)
[command]
```

## Deployment

```bash
# dev     → push to `develop`          (CI/CD auto-triggers)
# staging → push to `release/*`        (CI/CD auto-triggers)
# prod    → merge PR to `main`         (CI/CD auto-triggers)

# Emergency rollback — production
[command]
```
