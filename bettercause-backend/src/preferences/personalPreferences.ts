// src/preferences/personalPreferences.ts
import { Prisma } from '@prisma/client';

export const PERSONAL_VALUE_KEYS = [
  'vegan',
  'cruelty_free',
  'organic',
  'eco_friendly',
  'halal',
  'fair_labor',
] as const;

export type PersonalValueKey = (typeof PERSONAL_VALUE_KEYS)[number];

export const personalKeyToColumn: Record<PersonalValueKey, keyof Prisma.UserPersonalValuesUncheckedUpdateInput> = {
  vegan: 'vegan',
  cruelty_free: 'crueltyFree',
  organic: 'organic',
  eco_friendly: 'ecoFriendly',
  halal: 'halal',
  fair_labor: 'fairLabor',
};
