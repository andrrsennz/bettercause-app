-- CreateEnum
CREATE TYPE "CategoryType" AS ENUM ('food_beverages', 'beauty_care');

-- CreateTable
CREATE TABLE "UserPersonalValues" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "vegan" BOOLEAN NOT NULL DEFAULT false,
    "crueltyFree" BOOLEAN NOT NULL DEFAULT false,
    "organic" BOOLEAN NOT NULL DEFAULT false,
    "ecoFriendly" BOOLEAN NOT NULL DEFAULT false,
    "halal" BOOLEAN NOT NULL DEFAULT false,
    "fairLabor" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserPersonalValues_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserCategoryPreference" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "category" "CategoryType" NOT NULL,
    "key" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserCategoryPreference_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "UserPersonalValues_userId_key" ON "UserPersonalValues"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "UserCategoryPreference_userId_category_key_key" ON "UserCategoryPreference"("userId", "category", "key");

-- AddForeignKey
ALTER TABLE "UserPersonalValues" ADD CONSTRAINT "UserPersonalValues_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserCategoryPreference" ADD CONSTRAINT "UserCategoryPreference_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
