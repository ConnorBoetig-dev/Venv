"""
Routers package for FastAPI endpoints.
"""

from . import auth, health # future search and upload

__all__ = [
    "auth",
    "health",
    # future search and upload
]
