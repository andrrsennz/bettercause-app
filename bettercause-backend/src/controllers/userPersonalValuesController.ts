// src/controllers/userPersonalValuesController.ts
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { PERSONAL_VALUE_KEYS, personalKeyToColumn, PersonalValueKey } from '../preferences/personalPreferences';

const prisma = new PrismaClient();

// PATCH /api/users/:userId/preferences/personal
export const updatePersonalValue = async (req: Request, res: Response) => {
  console.log('🔍 UPDATE PERSONAL VALUE CALLED');
  console.log('🔍 userId:', req.params.userId);
  console.log('🔍 body:', JSON.stringify(req.body, null, 2));

  try {
    const userId = req.params.userId;
    const { key, value } = req.body as { key: string; value: boolean };

    if (!PERSONAL_VALUE_KEYS.includes(key as PersonalValueKey)) {
      console.log('❌ Invalid key:', key);
      console.log('❌ Valid keys are:', PERSONAL_VALUE_KEYS);
      return res.status(400).json({ message: 'Invalid personal value key' });
    }
    if (typeof value !== 'boolean') {
      console.log('❌ Invalid value type:', typeof value);
      return res.status(400).json({ message: 'value must be boolean' });
    }

    const typedKey = key as PersonalValueKey;
    const column = personalKeyToColumn[typedKey];

    console.log('🔍 Mapped key to column:', key, '→', column);

    // Ensure row exists, then update
    const result = await prisma.userPersonalValues.upsert({
      where: { userId },
      create: {
        userId,
        [column]: value,
      },
      update: {
        [column]: value,
      },
    });

    console.log('✅ UPSERT SUCCESSFUL:', JSON.stringify(result, null, 2));
    return res.json({ success: true });
  } catch (err) {
    console.error('❌ ERROR in updatePersonalValue:', err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};