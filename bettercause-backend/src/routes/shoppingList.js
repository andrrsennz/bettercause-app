// src/routes/shoppingList.js
const express = require("express");
const router = express.Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
const { requireUser } = require("../middleware/requireUser");

// GET /api/shopping-list
router.get("/", requireUser, async (req, res) => {
  const items = await prisma.shoppingListItem.findMany({
    where: { userId: req.userId },
    orderBy: { addedAt: "desc" },
  });

  res.json(items);
});

// POST /api/shopping-list
// body: { productId?, name, brand, imageUrl?, category? }
router.post("/", requireUser, async (req, res) => {
  const { productId, name, brand, imageUrl = "", category = "Food & Beverages" } = req.body;

  if (!name || !brand) {
    return res.status(400).json({ message: "name and brand are required" });
  }

  try {
    const created = await prisma.shoppingListItem.create({
      data: {
        userId: req.userId,
        productId: productId ?? null,
        name,
        brand,
        imageUrl,
        category,
      },
    });
    res.status(201).json(created);
  } catch (e) {
    // Unique constraint (duplicate product)
    if (e.code === "P2002") {
      return res.status(409).json({ message: "Item already exists in shopping list" });
    }
    res.status(500).json({ message: "Failed to add item", error: String(e) });
  }
});

// PATCH /api/shopping-list/:id/toggle
router.patch("/:id/toggle", requireUser, async (req, res) => {
  const { id } = req.params;

  const item = await prisma.shoppingListItem.findFirst({
    where: { id, userId: req.userId },
  });
  if (!item) return res.status(404).json({ message: "Item not found" });

  const updated = await prisma.shoppingListItem.update({
    where: { id },
    data: { isBought: !item.isBought },
  });

  res.json(updated);
});

// DELETE /api/shopping-list/:id
router.delete("/:id", requireUser, async (req, res) => {
  const { id } = req.params;

  const item = await prisma.shoppingListItem.findFirst({
    where: { id, userId: req.userId },
  });
  if (!item) return res.status(404).json({ message: "Item not found" });

  await prisma.shoppingListItem.delete({ where: { id } });
  res.json({ ok: true });
});

module.exports = router;
