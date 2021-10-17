module.exports = {
  port: 3001,
  reactStrictMode: true,
  webpackDevMiddleware: config => {
    config.watchOptions = {
      poll: 1000,
      aggregateTimeout: 300,
    }

    return config
  },
  async redirects() {
    return [
      {
        source: '/',
        destination: '/tables/candidates',
        permanent: true,
      },
    ]
  },
}
