const cirqleGrey = {
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

module.exports = {
  future: {
    hoverOnlyWhenSupported: true
  },
  theme: {
    extend: {
      colors: {
        ...Object.fromEntries(Object.entries(cirqleGrey).map(([shade, value]) => [`neutral-${shade}`, value])),
        gray: cirqleGrey
      },
      ringColor: {
        DEFAULT: '#f0531c'
      }
    }
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
          info: '#164a42',
          'info-content': '#f8f5ee',
          success: '#0a332d',
          'success-content': '#f8f5ee',
          warning: '#fb8258',
          'warning-content': '#252422',
          error: '#cf4313',
          'error-content': '#f8f5ee',
          '--rounded-btn': '1.9rem',
          '--tab-border': '2px',
          '--tab-radius': '.5rem'
        }
      }
    ]
  }
}
