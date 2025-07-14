import { useState, FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import './Register.css'

function Register() {
  const { register, isRegistering, registerError } = useAuth()
  const navigate = useNavigate()
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
  })
  const [showPassword, setShowPassword] = useState(false)
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({})

  const validatePassword = (password: string): string[] => {
    const errors: string[] = []
    
    if (password.length < 8) {
      errors.push('At least 8 characters long')
    }
    if (!/[A-Z]/.test(password)) {
      errors.push('One uppercase letter')
    }
    if (!/[a-z]/.test(password)) {
      errors.push('One lowercase letter')
    }
    if (!/\d/.test(password)) {
      errors.push('One number')
    }
    if (!/[!@#$%^&*()_+\-=[\]{}|;:,.<>?]/.test(password)) {
      errors.push('One special character')
    }
    
    return errors
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }))

    // Clear validation errors on change
    if (validationErrors[name]) {
      setValidationErrors(prev => {
        const newErrors = { ...prev }
        delete newErrors[name]
        return newErrors
      })
    }

    // Real-time password validation
    if (name === 'password') {
      const errors = validatePassword(value)
      if (errors.length > 0) {
        setValidationErrors(prev => ({
          ...prev,
          password: `Password must have: ${errors.join(', ')}`,
        }))
      }
    }
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    
    // Validate
    const errors: Record<string, string> = {}
    
    if (formData.password !== formData.confirmPassword) {
      errors.confirmPassword = 'Passwords do not match'
    }
    
    const passwordErrors = validatePassword(formData.password)
    if (passwordErrors.length > 0) {
      errors.password = `Password must have: ${passwordErrors.join(', ')}`
    }
    
    if (Object.keys(errors).length > 0) {
      setValidationErrors(errors)
      return
    }

    // Register
    try {
      await register.mutateAsync({
        email: formData.email,
        password: formData.password,
      })
      
      // Navigate to login with success message
      navigate('/login', { 
        state: { message: 'Registration successful! Please sign in.' }
      })
    } catch (error) {
      // Error is handled by the hook
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-container">
        <div className="auth-card">
          {/* Logo */}
          <div className="auth-logo">
            <span className="logo-icon">🖼️</span>
            <h1 className="logo-text">PG-VENV</h1>
          </div>

          {/* Title */}
          <div className="auth-header">
            <h2 className="auth-title">Create an account</h2>
            <p className="auth-subtitle">Start organizing your media with AI</p>
          </div>

          {/* Error message */}
          {registerError && (
            <div className="alert alert-error">
              <span>❌</span>
              <span>
                {registerError.response?.data?.detail || 'Registration failed. Please try again.'}
              </span>
            </div>
          )}

          {/* Form */}
          <form className="auth-form" onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="email" className="form-label">
                Email address
              </label>
              <input
                type="email"
                id="email"
                name="email"
                className="form-input"
                placeholder="you@example.com"
                value={formData.email}
                onChange={handleInputChange}
                required
                autoFocus
              />
            </div>

            <div className="form-group">
              <label htmlFor="password" className="form-label">
                Password
              </label>
              <div className="password-input-wrapper">
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="password"
                  name="password"
                  className={`form-input ${validationErrors.password ? 'input-error' : ''}`}
                  placeholder="Create a strong password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? '👁️' : '👁️‍🗨️'}
                </button>
              </div>
              {validationErrors.password && (
                <span className="field-error">{validationErrors.password}</span>
              )}
              
              {/* Password requirements */}
              <div className="password-requirements">
                <span className="requirement-label">Password must contain:</span>
                <ul className="requirement-list">
                  <li className={formData.password.length >= 8 ? 'met' : ''}>
                    ✓ At least 8 characters
                  </li>
                  <li className={/[A-Z]/.test(formData.password) ? 'met' : ''}>
                    ✓ One uppercase letter
                  </li>
                  <li className={/[a-z]/.test(formData.password) ? 'met' : ''}>
                    ✓ One lowercase letter
                  </li>
                  <li className={/\d/.test(formData.password) ? 'met' : ''}>
                    ✓ One number
                  </li>
                  <li className={/[!@#$%^&*()_+\-=[\]{}|;:,.<>?]/.test(formData.password) ? 'met' : ''}>
                    ✓ One special character
                  </li>
                </ul>
              </div>
            </div>

            <div className="form-group">
              <label htmlFor="confirmPassword" className="form-label">
                Confirm password
              </label>
              <input
                type={showPassword ? 'text' : 'password'}
                id="confirmPassword"
                name="confirmPassword"
                className={`form-input ${validationErrors.confirmPassword ? 'input-error' : ''}`}
                placeholder="Confirm your password"
                value={formData.confirmPassword}
                onChange={handleInputChange}
                required
              />
              {validationErrors.confirmPassword && (
                <span className="field-error">{validationErrors.confirmPassword}</span>
              )}
            </div>

            <button
              type="submit"
              className="submit-button"
              disabled={isRegistering}
            >
              {isRegistering ? (
                <>
                  <span className="button-spinner"></span>
                  <span>Creating account...</span>
                </>
              ) : (
                'Create account'
              )}
            </button>
          </form>

          {/* Footer */}
          <div className="auth-footer">
            <p className="footer-text">
              Already have an account?{' '}
              <Link to="/login" className="footer-link">
                Sign in
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Register
