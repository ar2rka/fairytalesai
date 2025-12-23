/**
 * Age category utilities
 * Converts between age categories and numeric age values for database storage
 */

export type AgeCategory = '2-3' | '3-5' | '5-7';

export const AGE_CATEGORIES: { value: AgeCategory; label: string }[] = [
  { value: '2-3', label: '2-3 года' },
  { value: '3-5', label: '3-5 лет' },
  { value: '5-7', label: '5-7 лет' },
];

/**
 * Converts age category to numeric age for database storage
 * Uses the middle value of the range, rounded down
 */
export function categoryToAge(category: AgeCategory): number {
  switch (category) {
    case '2-3':
      return 2; // Use lower bound to avoid overlap
    case '3-5':
      return 4; // Middle value
    case '5-7':
      return 6; // Middle value
    default:
      return 4;
  }
}

/**
 * Converts numeric age back to age category for display
 */
export function ageToCategory(age: number): AgeCategory {
  if (age <= 3) {
    return '2-3';
  } else if (age <= 5) {
    return '3-5';
  } else {
    return '5-7';
  }
}

/**
 * Gets display label for age category
 */
export function getCategoryLabel(category: AgeCategory): string {
  return AGE_CATEGORIES.find(c => c.value === category)?.label || category;
}

/**
 * Gets display label for numeric age
 */
export function getAgeDisplay(age: number): string {
  return getCategoryLabel(ageToCategory(age));
}
