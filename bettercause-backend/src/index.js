// src/index.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/auth.routes");

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "BetterCause API running" });
});

app.use("/api/auth", authRoutes);

app.listen(PORT, () => {
  console.log(`BetterCause API running at http://localhost:${PORT}`);
});
