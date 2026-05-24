# dependencies.py
# Define a dependência de autenticação usada para proteger rotas.
# O FastAPI injeta isso automaticamente em qualquer rota que declare
# `usuario_atual = Depends(obter_usuario_atual)`.

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from auth import verificar_token

# O FastAPI usa esse esquema para extrair o token do header:
# Authorization: Bearer <token>
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def obter_usuario_atual(token: str = Depends(oauth2_scheme)) -> str:
    """
    Dependência injetada nas rotas protegidas.
    Extrai e valida o JWT do header Authorization.
    Se inválido, retorna 401 automaticamente.
    """
    email = verificar_token(token)
    if email is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido ou expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return email
