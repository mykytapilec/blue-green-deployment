# Blue-Green Deployment

A Node.js application built with TypeScript and Express.js to demonstrate the Blue-Green Deployment strategy.

## Requirements

- Node.js
- npm

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

The application runs at `http://localhost:4000`.

## Available Endpoints

| Method | Endpoint   | Description                                    |
| ------ | ---------- | ---------------------------------------------- |
| GET    | `/health`  | Application health check                       |
| GET    | `/version` | Application version and deployment environment |

## Available Scripts

| Command                | Description              |
| ---------------------- | ------------------------ |
| `npm run dev`          | Start development server |
| `npm run build`        | Compile TypeScript       |
| `npm start`            | Start production server  |
| `npm run lint`         | Run ESLint               |
| `npm run format`       | Format source files      |
| `npm run format:check` | Check formatting         |
| `npm run typecheck`    | Check TypeScript types   |

## Environment Variables

| Variable           | Default | Description            |
| ------------------ | ------- | ---------------------- |
| `PORT`             | `3000`  | Application port       |
| `APP_VERSION`      | `1.0.0` | Application version    |
| `DEPLOYMENT_COLOR` | `local` | Deployment environment |

Copy `.env.example` to `.env` to configure local environment variables.
