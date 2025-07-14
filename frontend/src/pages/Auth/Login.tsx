import { useState, FormEvent } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import './Login.css'

function Login() {
  const { login, isLoggingIn, loginError } = useAuth()
  const location = useLocation()
  const [formData, setFormData] = useState({
    email: '',
    password: '',
  })
  const [showPassword, setShowPassword] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    
    // OAuth2 expects username field (with email value)
    await login.mutateAsync({
      username: formData.email,
      password: formData.password,
    })
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value,
    }))
  }

  // Get any message from navigation state (like from registration)
  const message = location.state?.message

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
            <h2 className="auth-title">Welcome back</h2>
            <p className="auth-subtitle">Sign in to your account</p>
          </div>

          {/* Success message */}
          {message && (
            <div className="alert alert-success">
              <span>✅</span>
              <span>{message}</span>
            </div>
          )}

          {/* Error message */}
          {loginError && (
            <div className="alert alert-error">
              <span>❌</span>
              <span>
                {loginError.response?.data?.detail || 'Login failed. Please try again.'}
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
                  className="form-input"
                  placeholder="Enter your password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required
                  minLength={8}
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
            </div>

            <button
              type="submit"
              className="submit-button"
              disabled={isLoggingIn}
            >
              {isLoggingIn ? (
                <>
                  <span className="button-spinner"></span>
                  <span>Signing in...</span>
                </>
              ) : (
                'Sign in'
              )}
            </button>
          </form>

          {/* Footer */}
          <div className="auth-footer">
            <p className="footer-text">
              Don't have an account?{' '}
              <Link to="/register" className="footer-link">
                Sign up
              </Link>
            </p>
          </div>
        </div>

        {/* Feature highlight */}
        <div className="auth-feature">
          <div className="feature-content">
            <h3 className="feature-title">Smart Media Search</h3>
            <p className="feature-description">
              Upload your photos and videos, then search them using natural language.
              Our AI understands what's in your media, making finding memories effortless.
            </p>
            <div className="feature-examples">
              <span className="example-chip">🏖️ "beach sunset"</span>
              <span className="example-chip">🎂 "birthday party"</span>
              <span className="example-chip">🐱 "funny cat video"</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Login
