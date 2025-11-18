// src/config/prisma.js
const { PrismaClient } = require("@prisma/client");

// In dev, reuse the same instance to avoid "too many connections" on hot reload
let prisma;

if (process.env.NODE_ENV === "production") {
  prisma = new PrismaClient();
} else {
  // @ts-ignore
  if (!global.__prisma) {
    // @ts-ignore
    global.__prisma = new PrismaClient();
  }
  // @ts-ignore
  prisma = global.__prisma;
}

module.exports = prisma;
