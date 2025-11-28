// src/controllers/userProfileController.ts
import { Request, Response } from 'express';
import { PrismaClient, CategoryType } from '@prisma/client';
import { PERSONAL_VALUE_KEYS } from '../preferences/personalPreferences';

const prisma = new PrismaClient();

// GET /api/users/:userId/profile
export const getUserProfile = async (req: Request, res: Response) => {
  try {
    const userId = req.params.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Get or create personal values row
    let personal = await prisma.userPersonalValues.findUnique({
      where: { userId },
    });

    if (!personal) {
      personal = await prisma.userPersonalValues.create({
        data: { userId },
      });
    }

    // Count enabled preferences per category
    const counts = await prisma.userCategoryPreference.groupBy({
      by: ['category'],
      where: {
        userId,
        enabled: true,
      },
      _count: {
        _all: true,
      },
    });

    const preferencesCount: Record<string, number> = {
      food_beverages: 0,
      beauty_care: 0,
    };

    counts.forEach((row) => {
      if (row.category === CategoryType.food_beverages) {
        preferencesCount.food_beverages = row._count._all;
      } else if (row.category === CategoryType.beauty_care) {
        preferencesCount.beauty_care = row._count._all;
      }
    });

    // Map DB row → response personalValues map
    const personalValues: Record<string, boolean> = {
      vegan: personal.vegan,
      cruelty_free: personal.crueltyFree,
      organic: personal.organic,
      eco_friendly: personal.ecoFriendly,
      halal: personal.halal,
      fair_labor: personal.fairLabor,
    };

    // TODO: replace these with real data if you have product scan/purchase tables
    const productScans = 14;
    const productsPurchased = 3;

    return res.json({
      name: user.name ?? 'User',
      memberSince: user.createdAt.toISOString(), // or format into "October 2025"
      productScans,
      productsPurchased,
      personalValues,
      categoryPreferences: {
        preferencesCount,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

export const getUserCategoryPreferences = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const { category } = req.query;

    if (!category || typeof category !== 'string') {
      return res.status(400).json({ message: 'Category query parameter is required' });
    }

    // Ensure the category string matches your Enum (optional safety check)
    // You might need to cast it to your Enum type
    const validCategories = Object.values(CategoryType).map(c => c.toString());
    if (!validCategories.includes(category)) {
         return res.status(400).json({ message: 'Invalid category' });
    }

    const preferences = await prisma.userCategoryPreference.findMany({
      where: {
        userId: userId,
        category: category as CategoryType, // Cast string to Enum
      },
    });

    return res.json(preferences);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};