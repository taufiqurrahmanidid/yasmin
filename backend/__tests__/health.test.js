const request = require('supertest')

describe('RS Yasmin Backend API', () => {
  let server
  let app

  beforeAll(async () => {
    // Set test environment
    process.env.NODE_ENV = 'test'
    process.env.JWT_SECRET = 'test-secret-for-jest-only'
    process.env.PORT = 0 // random port for tests

    // Load server after env setup
    const { default: serverModule } = await import('../server.js')
    server = serverModule
    app = server.app
  })

  afterAll(async () => {
    if (server) {
      await server.close()
    }
  })

  test('GET /health returns 200 and status OK', async () => {
    const response = await request(app).get('/health')
    expect(response.status).toBe(200)
    expect(response.body).toHaveProperty('status', 'OK')
    expect(response.body).toHaveProperty('timestamp')
    expect(typeof response.body.timestamp).toBe('string')
  })

  test('GET /health includes security headers', async () => {
    const response = await request(app).get('/health')
    expect(response.headers).toHaveProperty('strict-transport-security')
    expect(response.headers['strict-transport-security']).toContain('max-age=31536000')
    expect(response.headers).toHaveProperty('x-frame-options', 'DENY')
    expect(response.headers).toHaveProperty('x-content-type-options', 'nosniff')
    expect(response.headers).toHaveProperty('referrer-policy', 'no-referrer')
  })

  test('CORS allows whitelisted origins', async () => {
    const response = await request(app)
      .get('/health')
      .set('Origin', 'http://localhost:3000')
    expect(response.headers).toHaveProperty('access-control-allow-origin')
    expect(response.headers['access-control-allow-origin']).toBe('http://localhost:3000')
  })

  test('CORS blocks non-whitelisted origins', async () => {
    const response = await request(app)
      .get('/health')
      .set('Origin', 'http://evil.com')
    // Should not have CORS headers for blocked origins
    expect(response.headers['access-control-allow-origin']).toBeUndefined()
  })
})