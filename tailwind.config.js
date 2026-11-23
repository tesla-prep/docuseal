module.exports = {
  future: {
    hoverOnlyWhenSupported: true
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        docuseal: {
          'color-scheme': 'light',
          primary: '#d3cec3',
          secondary: '#fb8258',
          accent: '#f0531c',
          neutral: '#0a332d',
          'neutral-content': '#f8f5ee',
          'base-100': '#f8f5ee',
          'base-200': '#f5f0e3',
          'base-300': '#d3cec3',
          'base-content': '#252422',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
