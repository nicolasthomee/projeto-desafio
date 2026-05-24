# routers/auth.py
# Rotas: POST /auth/cadastro e POST /auth/login

from fastapi import APIRouter, HTTPException, status
from models import CadastroRequest, LoginRequest, TokenResponse, UsuarioPublico
from auth import cadastrar_usuario, autenticar_usuario, criar_token

router = APIRouter(prefix="/auth", tags=["Autenticação"])


@router.post("/cadastro", response_model=UsuarioPublico, status_code=201)
async def cadastro(body: CadastroRequest):
    """
    Cria um novo usuário.
    - Valida que a senha tem mínimo 6 caracteres (feito no modelo)
    - Verifica duplicata de e-mail
    - Salva com senha hasheada (bcrypt)

    async: libera a thread enquanto espera o banco responder.
    """
    try:
        usuario = cadastrar_usuario(body.email, body.senha)
        return UsuarioPublico(
            id=usuario["id"],
            email=usuario["email"],
            criado_em=usuario.get("criado_em"),
        )
    except ValueError as e:
        # E-mail duplicado — erro do cliente (400)
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        # Erro inesperado — erro do servidor (500)
        raise HTTPException(status_code=500, detail=f"Erro interno: {e}")


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest):
    """
    Autentica o usuário e retorna um JWT.
    O Flutter salva esse token e envia em todas as requisições seguintes.
    """
    usuario = autenticar_usuario(body.email, body.senha)
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-mail ou senha incorretos",
        )

    token = criar_token({"sub": usuario["email"]})
    return TokenResponse(access_token=token)
