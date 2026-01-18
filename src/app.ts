import express from "express";

const app = express();

app.use(express.json());

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

export default app;
