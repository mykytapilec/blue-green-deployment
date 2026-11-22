# Blue-Green Deployment

A containerized Node.js application demonstrating a Blue-Green Deployment strategy with automated traffic switching, health checks, continuous integration, and monitoring.

This project was built as a practical implementation of the [Blue-Green Deployment challenge on roadmap.sh](https://roadmap.sh/projects/blue-green-deployment).

## Overview

Blue-Green Deployment is a release strategy that uses two identical production environments:

- **Blue** — the currently active application version.
- **Green** — the alternative environment where a new application version can be deployed and verified.

A reverse proxy routes incoming traffic to the active environment. Once the alternative environment is healthy, traffic can be switched to it without changing the public application endpoint.

This project demonstrates the approach using Docker Compose, Nginx, Node.js, TypeScript, Prometheus, and Grafana.

## Architecture

```text
                         Client
                           |
                           v
                    +-------------+
                    |    Nginx    |
                    | Reverse Proxy|
                    +-------------+
                           |
                  Traffic Routing
                     /       \
                    /         \
                   v           v
          +-------------+ +-------------+
          |  App Blue   | |  App Green  |
          | Version 1.0 | | Version 1.1 |
          +-------------+ +-------------+
                  |             |
                  +------+------+
                         |
                  +------+------+
                  |             |
                  v             v
             +----------+  +----------+
             |Prometheus|  | Grafana  |
             +----------+  +----------+
```

### Application environments

| Component | Container              | Application version | Deployment color |
| --------- | ---------------------- | ------------------: | ---------------- |
| Blue      | `blue-green-app-blue`  |               1.0.0 | Blue             |
| Green     | `blue-green-app-green` |               1.1.0 | Green            |

Both application instances run independently and expose health and version endpoints.

### Traffic management

Nginx acts as the reverse proxy and routes incoming requests to the active application environment.

The traffic-switching mechanism updates the Nginx upstream configuration and reloads Nginx to apply the change.

Docker health checks are configured for both application instances.

## Technology Stack

| Technology     | Purpose                           |
| -------------- | --------------------------------- |
| Node.js 22     | JavaScript runtime                |
| TypeScript     | Application development           |
| Express 5      | HTTP server and API               |
| Docker         | Application containerization      |
| Docker Compose | Multi-container orchestration     |
| Nginx          | Reverse proxy and traffic routing |
| Prometheus     | Metrics collection                |
| Grafana        | Monitoring dashboards             |
| GitHub Actions | Continuous Integration            |
| ESLint         | Code linting                      |
| Prettier       | Code formatting                   |

## Project Structure

```text
blue-green-deployment/
├── .github/
│   └── workflows/
│       └── ci.yml
├── grafana/
│   ├── dashboards/
│   │   └── blue-green-dashboard.json
│   └── provisioning/
│       ├── dashboards/
│       │   └── dashboards.yml
│       └── datasources/
│           └── prometheus.yml
├── nginx/
│   └── default.conf
├── prometheus/
│   └── prometheus.yml
├── src/
│   ├── app.ts
│   └── server.ts
├── Dockerfile
├── docker-compose.yml
├── package.json
├── package-lock.json
└── tsconfig.json
```

## Getting Started

### Prerequisites

Make sure the following tools are installed:

- Node.js 22 or later
- npm
- Docker
- Docker Compose

### Installation

Clone the repository:

```bash
git clone https://github.com/mykytapilec/blue-green-deployment.git
cd blue-green-deployment
```

Install dependencies:

```bash
npm ci
```

### Environment Variables

The application supports the following environment variables:

| Variable           | Description                       | Default |
| ------------------ | --------------------------------- | ------- |
| `PORT`             | Application listening port        | `4000`  |
| `APP_VERSION`      | Application version               | `1.0.0` |
| `DEPLOYMENT_COLOR` | Deployment environment identifier | `local` |

## Running the Application Locally

Start the development server:

```bash
npm run dev
```

The application will be available at:

```text
http://localhost:4000
```

### Available API Endpoints

| Endpoint       | Description                                    |
| -------------- | ---------------------------------------------- |
| `GET /health`  | Application health check                       |
| `GET /version` | Application version and deployment information |
| `GET /metrics` | Prometheus metrics endpoint                    |

Example requests:

```bash
curl http://localhost:4000/health
curl http://localhost:4000/version
curl http://localhost:4000/metrics
```

## Docker Deployment

The project uses a multi-stage Dockerfile to build and run the TypeScript application in a production-oriented container image.

Build and start all services:

```bash
docker compose up -d --build
```

Check running containers:

```bash
docker compose ps
```

View application logs:

```bash
docker compose logs -f
```

### Service URLs

| Service                   | Local URL             |
| ------------------------- | --------------------- |
| Application through Nginx | http://localhost:8080 |
| Prometheus                | http://localhost:9091 |
| Grafana                   | http://localhost:3003 |

Both Blue and Green application instances are available internally through the Docker Compose network. External application traffic is routed through Nginx.

## Blue-Green Traffic Switching

The deployment contains two independent application environments:

- Blue runs version `1.0.0`.
- Green runs version `1.1.0`.

Nginx routes requests to the currently active environment.

The traffic-switching mechanism changes the active upstream after the target application has been deployed and verified.

This approach demonstrates how a new application version can be prepared and checked before receiving production traffic.

The application version and deployment color can be verified through:

```bash
curl http://localhost:8080/version
```

The health endpoint can be used to verify application availability:

```bash
curl http://localhost:8080/health
```

## Health Checks

Docker Compose defines health checks for both application containers.

Health checks help determine whether an application instance is ready to serve requests.

The health endpoint is:

```text
/health
```

This allows the deployment environment to verify application availability independently of the reverse proxy.

## Monitoring

The project integrates Prometheus and Grafana to monitor both application environments.

### Prometheus

Prometheus collects application metrics from both Blue and Green instances.

The configured scrape targets are:

```yaml
static_configs:
  - targets:
      - "app-blue:4000"
    labels:
      deployment_color: blue

  - targets:
      - "app-green:4000"
    labels:
      deployment_color: green
```

Prometheus is available at:

```text
http://localhost:9091
```

### Grafana

Grafana uses Prometheus as its configured data source.

The provisioned dashboard includes:

1. HTTP Requests Rate
2. Total HTTP Requests
3. HTTP Request Duration (p50, p95, p99)
4. Application Status
5. Requests by Deployment Color

Grafana is available at:

```text
http://localhost:3003
```

The default local administrator username is `admin`.

The administrator password is configurable through the `GRAFANA_ADMIN_PASSWORD` environment variable. If it is not provided, the Compose configuration uses `admin` as the default.

For any environment beyond local development, set a strong custom password using `GRAFANA_ADMIN_PASSWORD`.

## Continuous Integration

The project uses GitHub Actions to automatically validate changes.

The workflow is defined in:

```text
.github/workflows/ci.yml
```

The CI pipeline performs the following checks:

- Installs dependencies using `npm ci`.
- Runs ESLint.
- Checks TypeScript types.
- Builds the application.
- Checks code formatting with Prettier.
- Builds the Docker image.

The workflow runs on pushes to the configured branches and pull requests targeting the configured integration branches.

## Available NPM Scripts

| Command                | Description                   |
| ---------------------- | ----------------------------- |
| `npm run dev`          | Starts the development server |
| `npm run lint`         | Runs ESLint                   |
| `npm run typecheck`    | Checks TypeScript types       |
| `npm run build`        | Builds the application        |
| `npm run format:check` | Checks code formatting        |

## Verification

After starting the Docker Compose stack, verify the application:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/version
```

Check Prometheus targets:

```text
http://localhost:9091/targets
```

Both application targets should report an `UP` state.

Open Grafana and verify that the provisioned dashboard displays metrics from the Blue and Green environments.

Run the project quality checks:

```bash
npm run lint
npm run typecheck
npm run build
npm run format:check
```

Validate the Docker Compose configuration:

```bash
docker compose config
```

## Stopping the Environment

Stop and remove the running containers and network:

```bash
docker compose down
```

To also remove the named Docker volumes:

```bash
docker compose down -v
```

**Warning:** Removing volumes deletes the persisted Prometheus and Grafana data.

## Key Concepts Demonstrated

- Blue-Green Deployment strategy
- Running multiple application versions simultaneously
- Docker multi-stage builds
- Docker Compose orchestration
- Nginx reverse proxy configuration
- Automated traffic switching
- Application health checks
- Prometheus metrics collection
- Grafana dashboard provisioning
- Continuous Integration with GitHub Actions
- TypeScript application development

## Roadmap Challenge

This repository is a practical implementation of the following roadmap.sh project:

[Blue-Green Deployment — roadmap.sh](https://roadmap.sh/projects/blue-green-deployment)

## Author

**GitHub:** [mykytapilec](https://github.com/mykytapilec)

**Repository:** [blue-green-deployment](https://github.com/mykytapilec/blue-green-deployment)

---

This project was created for educational purposes to practice containerization, deployment strategies, reverse proxy configuration, monitoring, and CI automation.
