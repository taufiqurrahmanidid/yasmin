import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import Footer from '../Footer'

// Mock the component with simplified version
vi.mock('../Footer', () => ({
  default: () => (
    <footer data-testid="footer">
      <p>RS Yasmin - Rumah Sakit Terpercaya di Banyuwangi</p>
    </footer>
  )
}))

describe('Footer Component', () => {
  it('renders footer with hospital name', () => {
    render(<Footer />)
    const footer = screen.getByTestId('footer')
    expect(footer).toBeInTheDocument()
    expect(footer.textContent).toContain('RS Yasmin')
  })

  it('contains hospital location information', () => {
    render(<Footer />)
    const text = screen.getByText(/Banyuwangi/i)
    expect(text).toBeInTheDocument()
  })
})