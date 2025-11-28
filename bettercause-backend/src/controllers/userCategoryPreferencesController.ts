// src/controllers/userCategoryPreferencesController.ts
import { Request, Response } from 'express';
import { PrismaClient, CategoryType } from '@prisma/client';

const prisma = new PrismaClient();

const CATEGORY_TYPES = ['food_beverages', 'beauty_care'] as const;
type CategoryTypeString = (typeof CATEGORY_TYPES)[number];

const toCategoryEnum = (c: string): CategoryType | null => {
  if (c === 'food_beverages') return CategoryType.food_beverages;
  if (c === 'beauty_care') return CategoryType.beauty_care;
  return null;
};

// GET /api/users/:userId/preferences/category?category=food_beverages
export const getCategoryPreferences = async (req: Request, res: Response) => {
  console.log('🔍 GET CATEGORY PREFERENCES CALLED');
  console.log('🔍 userId:', req.params.userId);
  console.log('🔍 category:', req.query.category);
  
  try {
    const userId = req.params.userId;
    const categoryParam = req.query.category as string | undefined;

    if (!categoryParam) {
      console.log('❌ No category param provided');
      return res.status(400).json({ message: 'category query param is required' });
    }

    const categoryEnum = toCategoryEnum(categoryParam);
    if (!categoryEnum) {
      console.log('❌ Invalid category:', categoryParam);
      return res.status(400).json({ message: 'Invalid category' });
    }

    console.log('🔍 Querying database...');
    const prefs = await prisma.userCategoryPreference.findMany({
      where: {
        userId,
        category: categoryEnum,
      },
    });

    console.log('🔍 Database returned:', prefs.length, 'preferences');
    console.log('🔍 Preferences:', JSON.stringify(prefs, null, 2));

    // ALWAYS return an object with preferences key, even if empty
    const map: Record<string, boolean> = {};
    prefs.forEach((p) => {
      map[p.key] = p.enabled;
    });

    const response = {
      category: categoryParam,
      preferences: map,
    };

    console.log('✅ SENDING RESPONSE:', JSON.stringify(response, null, 2));
    return res.json(response);
  } catch (err) {
    console.error('❌ ERROR in getCategoryPreferences:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

// PATCH /api/users/:userId/preferences/category
export const updateCategoryPreference = async (req: Request, res: Response) => {
  console.log('🔍 UPDATE CATEGORY PREFERENCE CALLED');
  console.log('🔍 userId:', req.params.userId);
  console.log('🔍 body:', JSON.stringify(req.body, null, 2));
  
  try {
    const userId = req.params.userId;
    const { category, key, value } = req.body as {
      category: string;
      key: string;
      value: boolean;
    };

    if (!CATEGORY_TYPES.includes(category as CategoryTypeString)) {
      console.log('❌ Invalid category:', category);
      return res.status(400).json({ message: 'Invalid category' });
    }
    if (!key || typeof key !== 'string') {
      console.log('❌ Invalid key:', key);
      return res.status(400).json({ message: 'key is required' });
    }
    if (typeof value !== 'boolean') {
      console.log('❌ Invalid value:', value);
      return res.status(400).json({ message: 'value must be boolean' });
    }

    const categoryEnum = toCategoryEnum(category)!;

    console.log('🔍 Upserting preference...');
    console.log('🔍 userId:', userId);
    console.log('🔍 category:', categoryEnum);
    console.log('🔍 key:', key);
    console.log('🔍 enabled:', value);

    const result = await prisma.userCategoryPreference.upsert({
      where: {
        userId_category_key: {
          userId,
          category: categoryEnum,
          key,
        },
      },
      create: {
        userId,
        category: categoryEnum,
        key,
        enabled: value,
      },
      update: {
        enabled: value,
      },
    });

    console.log('✅ UPSERT SUCCESSFUL:', JSON.stringify(result, null, 2));
    return res.json({ success: true });
  } catch (err) {
    console.error('❌ ERROR in updateCategoryPreference:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};