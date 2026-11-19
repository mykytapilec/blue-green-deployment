import express from "express";

import {
  httpRequestDurationSeconds,
  httpRequestsTotal,
  register,
} from "./metrics.js";

const app = express();

app.use(express.json());

app.use((req, res, next) => {
  if (req.path === "/metrics") {
    next();
    return;
  }

  const startTime = process.hrtime.bigint();

  res.on("finish", () => {
    const route = req.route?.path
      ? `${req.baseUrl}${req.route.path}`
      : "unmatched";

    const labels = {
      method: req.method,
      route,
      status_code: String(res.statusCode),
    };

    httpRequestsTotal.inc(labels);

    const duration = Number(process.hrtime.bigint() - startTime) / 1e9;

    httpRequestDurationSeconds.observe(labels, duration);
  });

  next();
});

app.get("/health", (_req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
  });
});

app.get("/version", (_req, res) => {
  res.status(200).json({
    version: process.env.APP_VERSION ?? "1.0.0",
    environment: process.env.DEPLOYMENT_COLOR ?? "local",
  });
});

app.get("/metrics", async (_req, res, next) => {
  try {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    next(error);
  }
});

export default app;
