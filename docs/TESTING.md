# Testing Guide - RS Yasmin

## Backend (Jest)

### Run Tests

```bash
# Run all tests
npm test --prefix backend

# Watch mode
npm run test:watch --prefix backend

# Coverage report
npm run test:coverage --prefix backend
```

### Test Structure

```
backend/
├── __tests__/
│   ├── health.test.js      # Health endpoint tests
│   ├── auth.test.js        # Authentication tests (add later)
│   └── api/
│       ├── patients.test.js
│       └── doctors.test.js
└── jest.config.js
```

### Coverage Thresholds

- Branches: 50%
- Functions: 50%
- Lines: 50%
- Statements: 50%

## Frontend (Vitest)

### Run Tests

```bash
# Run all tests
npm test --prefix frontend

# Watch mode
npm run test:watch --prefix frontend

# UI mode
npm run test:ui --prefix frontend

# Coverage report
npm run test:coverage --prefix frontend
```

### Test Structure

```
frontend/src/
├── test/
│   └── setup.ts            # Test setup & mocks
├── components/
│   └── __tests__/
│       ├── Footer.test.tsx
│       └── Header.test.tsx
└── utils/
    └── __tests__/
        └── helpers.test.ts
```

### Coverage Thresholds

- Branches: 40%
- Functions: 40%
- Lines: 40%
- Statements: 40%

## CI Integration

Tests run automatically on:
- Push to main/master/develop
- Pull requests

### CI Commands

```bash
# Backend CI
npm run test:ci --prefix backend

# Frontend CI
npm test --prefix frontend
```

## Writing Tests

### Backend API Test Example

```javascript
const request = require('supertest')

describe('API Endpoint', () => {
  test('GET /api/endpoint returns 200', async () => {
    const response = await request(app).get('/api/endpoint')
    expect(response.status).toBe(200)
  })
})
```

### Frontend Component Test Example

```typescript
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import MyComponent from '../MyComponent'

describe('MyComponent', () => {
  it('renders correctly', () => {
    render(<MyComponent />)
    expect(screen.getByText('Expected Text')).toBeInTheDocument()
  })
})
```

## Test Coverage Reports

### View Coverage

- Backend: `backend/coverage/lcov-report/index.html`
- Frontend: `frontend/coverage/index.html`

### Upload to Codecov (Optional)

```yaml
# Add to .github/workflows/build.yml
- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./backend/coverage/lcov.info,./frontend/coverage/coverage-final.json
```

## Best Practices

1. **Test Critical Paths First**
   - Authentication
   - Patient data CRUD
   - Payment flows

2. **Use Descriptive Test Names**
   ```javascript
   test('POST /api/auth/login returns 401 for invalid credentials', async () => {
     // test body
   })
   ```

3. **Mock External Dependencies**
   - Database calls
   - API requests
   - File system

4. **Keep Tests Fast**
   - Use in-memory database for tests
   - Parallelize tests
   - Avoid real network calls

5. **Test Edge Cases**
   - Empty inputs
   - Null values
   - Large payloads
   - Concurrent requests

## Current Test Coverage

| Module | Coverage | Status |
|--------|----------|--------|
| Backend API | Basic | Needs expansion |
| Frontend Components | Basic | Needs expansion |
| Security Headers | ✓ Complete | Tested |
| CORS | ✓ Complete | Tested |
| Rate Limiting | ✓ Complete | Manual test |

## TODO

- [ ] Add auth tests (login, register, JWT)
- [ ] Add patient CRUD tests
- [ ] Add doctor schedule tests
- [ ] Add integration tests
- [ ] Add E2E tests (Playwright/Cypress)
