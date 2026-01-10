import dotenv from 'dotenv';
import express, { Request, Response } from 'express';
import cors from 'cors';

// Import your routes
// Note: If auth.routes is still .js, we use require, or convert it to TS too.
// Assuming auth.routes is JS:
const authRoutes = require("./routes/auth.routes"); 
import userRoutes from './routes/userRoutes';

// ✅ NEW: Import the shopping list route (using require because it is a .js file)
const shoppingListRoutes = require("./routes/shoppingList");

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

app.get("/", (req: Request, res: Response) => {
  res.json({ message: "BetterCause API running" });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api", userRoutes);

// ✅ NEW: Mount the shopping list route
app.use("/api/shopping-list", shoppingListRoutes);

app.listen(PORT, () => {
  console.log(`BetterCause API running at http://localhost:${PORT}`);
});