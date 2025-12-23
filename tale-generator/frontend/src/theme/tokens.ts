/**
 * Design Tokens
 * Central source of truth for design values used throughout the application
 */

export const colors = {
  // Primary - Light blue/cyan (#99CDD8)
  primary: {
    50: '#f0f9fa',
    100: '#e6f5f7',
    200: '#cceef3',
    300: '#99CDD8',
    400: '#7db8c4',
    500: '#6ba3b0',
    600: '#5a8e9c',
    700: '#4a7885',
    800: '#3c616d',
    900: '#2e4a55',
  },
  // Secondary - Mint/green (#DAEBE3)
  secondary: {
    50: '#f5faf8',
    100: '#ebf5f1',
    200: '#DAEBE3',
    300: '#c2d9ce',
    400: '#aac7b9',
    500: '#92b5a4',
    600: '#7ba38f',
    700: '#65817a',
    800: '#4f5f65',
    900: '#393d50',
  },
  // Accent - Warm peach (#FDE8D3)
  accent: {
    50: '#fffbf7',
    100: '#fff5eb',
    200: '#FDE8D3',
    300: '#fbd5b5',
    400: '#f9c297',
    500: '#f7af79',
    600: '#f59c5b',
    700: '#d1844e',
    800: '#ad6c41',
    900: '#895434',
  },
  // Warm - Coral/salmon (#F3C3B2)
  warm: {
    50: '#fef7f4',
    100: '#fcefe8',
    200: '#F3C3B2',
    300: '#eda595',
    400: '#e78778',
    500: '#e1695b',
    600: '#db4b3e',
    700: '#b93e35',
    800: '#97312b',
    900: '#752421',
  },
  // Neutral - Sage/green-gray (#CFD6C4)
  neutral: {
    50: '#f7f8f5',
    100: '#eff0eb',
    200: '#CFD6C4',
    300: '#b7c2a8',
    400: '#9fae8c',
    500: '#879a70',
    600: '#6f8654',
    700: '#5a6f44',
    800: '#455834',
    900: '#304124',
  },
  // Semantic colors
  success: {
    50: '#f0fdf4',
    100: '#dcfce7',
    500: '#22c55e',
    600: '#16a34a',
    700: '#15803d',
  },
  warning: {
    50: '#fffbeb',
    100: '#fef3c7',
    500: '#f59e0b',
    600: '#d97706',
    700: '#b45309',
  },
  error: {
    50: '#fef2f2',
    100: '#fee2e2',
    500: '#ef4444',
    600: '#dc2626',
    700: '#b91c1c',
  },
  info: {
    50: '#eff6ff',
    100: '#dbeafe',
    500: '#3b82f6',
    600: '#2563eb',
    700: '#1d4ed8',
  },
} as const;

export const typography = {
  fontFamily: {
    sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
    display: ['Outfit', 'Inter', 'system-ui', 'sans-serif'],
    mono: ['Monaco', 'Courier New', 'monospace'],
  },
  fontSize: {
    xs: '0.6875rem',   // 11px (reduced from 12px)
    sm: '0.8125rem',   // 13px (reduced from 14px)
    base: '0.9375rem', // 15px (reduced from 16px)
    lg: '1rem',        // 16px (reduced from 18px)
    xl: '1.125rem',    // 18px (reduced from 20px)
    '2xl': '1.375rem', // 22px (reduced from 24px)
    '3xl': '1.6875rem', // 27px (reduced from 30px)
    '4xl': '2rem',     // 32px (reduced from 36px)
    '5xl': '2.625rem', // 42px (reduced from 48px)
    '6xl': '3.375rem', // 54px (reduced from 60px)
  },
  fontWeight: {
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    extrabold: '800',
  },
  lineHeight: {
    tight: '1.25',
    normal: '1.5',
    relaxed: '1.75',
  },
} as const;

export const spacing = {
  0: '0',
  1: '0.25rem',   // 4px
  2: '0.5rem',    // 8px
  3: '0.75rem',   // 12px
  4: '1rem',      // 16px
  5: '1.25rem',   // 20px
  6: '1.5rem',    // 24px
  8: '2rem',      // 32px
  10: '2.5rem',   // 40px
  12: '3rem',     // 48px
  16: '4rem',     // 64px
  20: '5rem',     // 80px
  24: '6rem',     // 96px
  32: '8rem',     // 128px
} as const;

export const borderRadius = {
  none: '0',
  sm: '0.25rem',   // 4px
  base: '0.375rem', // 6px
  md: '0.5rem',    // 8px
  lg: '0.75rem',   // 12px
  xl: '1rem',      // 16px
  '2xl': '1.5rem', // 24px
  '3xl': '2rem',   // 32px
  full: '9999px',
} as const;

export const shadows = {
  sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
  base: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
  md: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
  lg: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
  xl: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
  '2xl': '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
  inner: 'inset 0 2px 4px 0 rgba(0, 0, 0, 0.06)',
  colored: {
    primary: '0 10px 25px -5px rgba(153, 205, 216, 0.3)',
    secondary: '0 10px 25px -5px rgba(218, 235, 227, 0.3)',
    accent: '0 10px 25px -5px rgba(253, 232, 211, 0.3)',
  },
} as const;

export const animations = {
  duration: {
    fast: '150ms',
    normal: '250ms',
    slow: '350ms',
    slower: '500ms',
  },
  easing: {
    linear: 'linear',
    ease: 'ease',
    easeIn: 'cubic-bezier(0.4, 0, 1, 1)',
    easeOut: 'cubic-bezier(0, 0, 0.2, 1)',
    easeInOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
    bounce: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
  },
} as const;

export const breakpoints = {
  sm: '640px',
  md: '768px',
  lg: '1024px',
  xl: '1280px',
  '2xl': '1536px',
} as const;

export const zIndex = {
  dropdown: 1000,
  sticky: 1020,
  modal: 1030,
  popover: 1040,
  tooltip: 1050,
} as const;
