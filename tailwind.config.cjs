module.exports = {
  content: ['./index.html', './assets/js/**/*.js'],
  corePlugins: { preflight: false },
  theme: {
    extend: {
      screens: {
        narrow: { max: '1050px' },
        'no-toc': { max: '820px' },
        mobile: { max: '640px' },
      },
    },
  },
};
