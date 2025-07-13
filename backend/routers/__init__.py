"""
Routers package for FastAPI endpoints.
"""

from . import auth, health, upload  # future search

__all__ = [
    "auth",
    "health",
    "upload",
    # future search
]
