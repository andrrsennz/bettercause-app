// src/routes/userRoutes.ts
import { Router } from 'express';
import { getUserProfile } from '../controllers/userProfileController';
import { 
  getCategoryPreferences, 
  updateCategoryPreference 
} from '../controllers/userCategoryPreferencesController';
// ✅ ADD THIS IMPORT
import { updatePersonalValue } from '../controllers/userPersonalValuesController';

const router = Router();

// Profile route
router.get('/users/:userId/profile', getUserProfile);

// Category preferences routes (Food & Beverages, Beauty & Care)
router.get('/users/:userId/preferences/category', getCategoryPreferences);
router.patch('/users/:userId/preferences/category', updateCategoryPreference);

// ✅ ADD THIS ROUTE - Personal values (Vegan, Cruelty-free, etc.)
router.patch('/users/:userId/preferences/personal', updatePersonalValue);

export default router;