/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
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
      },
      fontSize: {
        xs: ['0.6875rem', { lineHeight: '1.5' }],   // 11px
        sm: ['0.8125rem', { lineHeight: '1.5' }],   // 13px
        base: ['0.9375rem', { lineHeight: '1.5' }], // 15px
        lg: ['1rem', { lineHeight: '1.5' }],        // 16px
        xl: ['1.125rem', { lineHeight: '1.5' }],    // 18px
        '2xl': ['1.375rem', { lineHeight: '1.35' }], // 22px
        '3xl': ['1.6875rem', { lineHeight: '1.3' }], // 27px
        '4xl': ['2rem', { lineHeight: '1.25' }],     // 32px
        '5xl': ['2.625rem', { lineHeight: '1.2' }],  // 42px
        '6xl': ['3.375rem', { lineHeight: '1.15' }], // 54px
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      boxShadow: {
        'soft': '0 1px 3px 0 rgba(0, 0, 0, 0.05), 0 1px 2px 0 rgba(0, 0, 0, 0.03)',
        'soft-md': '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03)',
        'soft-lg': '0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.03)',
      },
      animation: {
        'fade-in': 'fadeIn 0.25s ease-out',
        'slide-up': 'slideUp 0.35s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
