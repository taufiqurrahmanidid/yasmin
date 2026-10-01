import { afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'
import '@testing-library/jest-dom/vitest'

// Clear DOM after each test
afterEach(() => {
  cleanup()
})

// Mock fetch for API tests
global.fetch = vi.fn()

// Mock localStorage
Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn()
  },
  writable: true
})

// Mock sessionStorage
Object.defineProperty(window, 'sessionStorage', {
  value: {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn()
  },
  writable: true
})

// Mock URL for Next.js compatibility
Object.defineProperty(window, 'URL', {
  value: {
    createObjectURL: vi.fn(),
    revokeObjectURL: vi.fn()
  },
  writable: true
})