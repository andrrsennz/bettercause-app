-- CreateTable
CREATE TABLE "ShoppingListItem" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "productId" TEXT,
    "name" TEXT NOT NULL,
    "brand" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL DEFAULT '',
    "category" TEXT NOT NULL DEFAULT 'Food & Beverages',
    "isBought" BOOLEAN NOT NULL DEFAULT false,
    "addedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ShoppingListItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ShoppingListItem_userId_idx" ON "ShoppingListItem"("userId");

-- CreateIndex
CREATE INDEX "ShoppingListItem_userId_isBought_idx" ON "ShoppingListItem"("userId", "isBought");

-- CreateIndex
CREATE UNIQUE INDEX "ShoppingListItem_userId_productId_key" ON "ShoppingListItem"("userId", "productId");
