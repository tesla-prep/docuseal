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
        'base-content': '#252422'
      }
    }
  }
}
