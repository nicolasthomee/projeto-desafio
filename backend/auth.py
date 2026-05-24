# auth.py
# Lógica de autenticação: hash de senha e geração/verificação de JWT.
#
# Controle transacional aqui:
#   Ao cadastrar, primeiro verificamos se o e-mail já existe,
#   depois inserimos. Se a inserção falhar, o erro é capturado e
#   nenhum dado parcial fica salvo — atomicidade da operação.

import os
from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from passlib.context import CryptContext
from dotenv import load_dotenv
from database import get_supabase

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "troque_isso")
ALGORITHM  = os.getenv("ALGORITHM", "HS256")
EXPIRE_MIN = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))

# CryptContext configura o algoritmo de hash (bcrypt).
# bcrypt é resistente a ataques de força bruta por ser lento por design.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)


def hash_senha(senha: str) -> str:
    """Gera o hash bcrypt da senha. Nunca salvamos a senha em texto puro."""
    return pwd_context.hash(senha)


def verificar_senha(senha_plana: str, senha_hash: str) -> bool:
    """Compara a senha fornecida com o hash salvo no banco."""
    return pwd_context.verify(senha_plana, senha_hash)


def criar_token(dados: dict) -> str:
    """
    Gera um JWT assinado com SECRET_KEY.
    O token carrega o e-mail do usuário e expira em EXPIRE_MIN minutos.
    Após expirar, o Flutter precisa fazer login novamente.
    """
    payload = dados.copy()
    expiracao = datetime.now(timezone.utc) + timedelta(minutes=EXPIRE_MIN)
    payload.update({"exp": expiracao})
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def verificar_token(token: str) -> str | None:
    """
    Decodifica e valida o JWT.
    Retorna o e-mail do usuário se válido, None se inválido/expirado.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        return email
    except JWTError:
        return None


def cadastrar_usuario(email: str, senha: str) -> dict:
    """
    Cria um novo usuário no banco.

    Controle transacional:
      1. Verifica se e-mail já existe (evita duplicatas)
      2. Insere o novo usuário
      Se qualquer etapa falhar, lança exceção — nada é salvo pela metade.
    """
    db = get_supabase()

    # Etapa 1: verificar duplicata
    existente = db.table("usuarios").select("id").eq("email", email).execute()
    if existente.data:
        raise ValueError("E-mail já cadastrado")

    # Etapa 2: inserir (se falhar, o erro propaga — sem dados parciais)
    novo = db.table("usuarios").insert({
        "email": email,
        "senha_hash": hash_senha(senha)
    }).execute()

    if not novo.data:
        raise RuntimeError("Falha ao inserir usuário no banco")

    return novo.data[0]


def autenticar_usuario(email: str, senha: str) -> dict | None:
    """
    Busca o usuário pelo e-mail e verifica a senha.
    Retorna os dados do usuário ou None se credenciais inválidas.
    """
    db = get_supabase()

    resultado = db.table("usuarios").select("*").eq("email", email).execute()
    if not resultado.data:
        return None

    usuario = resultado.data[0]
    if not verificar_senha(senha, usuario["senha_hash"]):
        return None

    return usuario
