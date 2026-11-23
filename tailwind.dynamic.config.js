const path = require('path')

module.exports = {
  future: {
    hoverOnlyWhenSupported: true
  },
  content: [
    path.resolve(__dirname, 'app/javascript/template_builder/dynamic_area.vue'),
    path.resolve(__dirname, 'app/javascript/template_builder/dynamic_section.vue')
  ],
  theme: {
    extend: {
      colors: {
        'base-100': '#f8f5ee',
        'base-200': '#f5f0e3',
        'base-300': '#d3cec3',
        'base-content': '#252422',
        neutral: {
          50: '#f8f5ee',
          100: '#f5f0e3',
          200: '#d3cec3',
          300: '#d3cec3',
          400: '#474544',
          500: '#474544',
          600: '#474544',
          700: '#252422',
          800: '#252422',
          900: '#0d0d0d',
          950: '#0d0d0d'
        },
        gray: {
          50: '#f8f5ee',
          100: '#f5f0e3',
          200: '#d3cec3',
          300: '#d3cec3',
          400: '#474544',
          500: '#474544',
          600: '#474544',
          700: '#252422',
          800: '#252422',
          900: '#0d0d0d',
          950: '#0d0d0d'
        }
      }
    }
  }
}
