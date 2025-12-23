"""Authentication middleware for FastAPI to verify Supabase JWT tokens."""

import os
import logging
from typing import Optional
from fastapi import HTTPException, Security, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
from jwt import PyJWKClient
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set up logger
logger = logging.getLogger("tale_generator.auth")

# Security scheme
security = HTTPBearer()

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET")

if not SUPABASE_URL:
    raise ValueError("SUPABASE_URL environment variable is required")


class AuthUser:
    """Represents an authenticated user."""
    
    def __init__(self, user_id: str, email: str, metadata: dict = None):
        self.user_id = user_id
        self.email = email
        self.metadata = metadata or {}
    
    def __repr__(self):
        return f"AuthUser(user_id={self.user_id}, email={self.email})"


def verify_token(token: str) -> dict:
    """
    Verify Supabase JWT token and return decoded payload.
    
    Args:
        token: JWT token string
        
    Returns:
        Decoded token payload
        
    Raises:
        HTTPException: If token is invalid or expired
    """
    logger.info(f"Verifying token, SUPABASE_JWT_SECRET present: {bool(SUPABASE_JWT_SECRET)}")
    try:
        # Option 1: Verify using JWT secret (if available)
        if SUPABASE_JWT_SECRET:
            logger.debug("Using JWT secret for verification")
            payload = jwt.decode(
                token,
                SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                options={"verify_aud": False}
            )
            logger.info(f"Token verified successfully, user_id: {payload.get('sub')}")
            return payload
        
        # Option 2: Verify using JWKS (public keys from Supabase)
        else:
            logger.debug("Using JWKS for verification")
            jwks_url = f"{SUPABASE_URL}/auth/v1/jwks"
            logger.debug(f"JWKS URL: {jwks_url}")
            jwks_client = PyJWKClient(jwks_url)
            signing_key = jwks_client.get_signing_key_from_jwt(token)
            
            payload = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256"],
                options={"verify_aud": False}
            )
            logger.info(f"Token verified successfully, user_id: {payload.get('sub')}")
            return payload
            
    except jwt.ExpiredSignatureError:
        logger.warning("Token has expired")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid token: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        logger.error(f"Error verifying token: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> AuthUser:
    """
    Dependency to get the current authenticated user from JWT token.
    
    Args:
        credentials: HTTP authorization credentials
        
    Returns:
        AuthUser object with user information
        
    Raises:
        HTTPException: If authentication fails
        
    Usage:
        @app.get("/protected")
        async def protected_route(user: AuthUser = Depends(get_current_user)):
            return {"user_id": user.user_id}
    """
    logger.info(f"Authenticating request, credentials type: {type(credentials)}")
    token = credentials.credentials
    logger.debug(f"Token (first 20 chars): {token[:20]}...")
    payload = verify_token(token)
    
    # Extract user information from token payload
    user_id = payload.get("sub")
    email = payload.get("email")
    user_metadata = payload.get("user_metadata", {})
    
    logger.info(f"Extracted user_id: {user_id}, email: {email}")
    
    if not user_id:
        logger.error("Token payload missing user ID")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    logger.info(f"Authentication successful for user: {user_id}")
    return AuthUser(user_id=user_id, email=email, metadata=user_metadata)


def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[AuthUser]:
    """
    Dependency to optionally get the current authenticated user.
    Returns None if no valid authentication is provided.
    
    Args:
        credentials: HTTP authorization credentials (optional)
        
    Returns:
        AuthUser object if authenticated, None otherwise
        
    Usage:
        @app.get("/optional-auth")
        async def optional_auth_route(user: Optional[AuthUser] = Depends(get_optional_user)):
            if user:
                return {"authenticated": True, "user_id": user.user_id}
            return {"authenticated": False}
    """
    if not credentials:
        return None
    
    try:
        return get_current_user(credentials)
    except HTTPException:
        return None
