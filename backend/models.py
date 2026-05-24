# models.py
# Todos os modelos são imutáveis (model_config frozen=True).
# Isso significa que após criados, os campos não podem ser alterados —
# não há setters. Os dados entram apenas pelo construtor (__init__).
# Isso garante integridade e previsibilidade dos dados em toda a aplicação.

from pydantic import BaseModel, EmailStr, field_validator
from datetime import datetime, date
from typing import Optional


class ModeloImutavel(BaseModel):
    """
    Classe base que torna todos os modelos imutáveis.
    frozen=True: bloqueia qualquer atribuição após a criação do objeto.
    Equivale a não ter setters — os dados só entram pelo construtor.
    """
    model_config = {"frozen": True}


# ── Autenticação ──────────────────────────────────────────────────────────────

class CadastroRequest(ModeloImutavel):
    """Dados recebidos para criar um novo usuário."""
    email: str
    senha: str

    @field_validator("senha")
    @classmethod
    def senha_minima(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("A senha deve ter no mínimo 6 caracteres")
        return v


class LoginRequest(ModeloImutavel):
    """Dados recebidos para autenticar um usuário."""
    email: str
    senha: str


class TokenResponse(ModeloImutavel):
    """Resposta retornada após login bem-sucedido."""
    access_token: str
    token_type: str = "bearer"


class UsuarioPublico(ModeloImutavel):
    """Dados do usuário que podem ser expostos (sem senha)."""
    id: int
    email: str
    criado_em: Optional[datetime] = None


# ── Produção ──────────────────────────────────────────────────────────────────

class ProducaoItem(ModeloImutavel):
    """
    Representa um registro da tabela 'producao'.
    Cada linha é uma leitura salva pelo Node-RED em tempo real.
    """
    id: int
    contador: int
    status: str
    alerta: str
    tempo_parado: int
    criado_em: Optional[datetime] = None


# ── Histórico Diário ──────────────────────────────────────────────────────────

class HistoricoItem(ModeloImutavel):
    """
    Representa um registro da tabela 'historico_diario'.
    Salvo ao encerrar o expediente (FECHAR_DIA).
    """
    id: int
    data: Optional[date] = None
    total_pecas: int
    tempo_parado_seg: int
    total_alertas: int
    criado_em: Optional[datetime] = None


# ── Relatórios ────────────────────────────────────────────────────────────────

class RelatorioResponse(ModeloImutavel):
    """Agregações calculadas sobre o histórico diário."""
    media_pecas: float
    maximo_pecas: int
    minimo_pecas: int
    total_dias: int
    media_tempo_parado_seg: float
    total_alertas: int


# ── Comando ───────────────────────────────────────────────────────────────────

COMANDOS_VALIDOS = {"PAUSAR", "RETOMAR", "SILENCIAR", "RESET", "FECHAR_DIA"}


class ComandoRequest(ModeloImutavel):
    """Comando a ser publicado no tópico MQTT do ESP32."""
    comando: str

    @field_validator("comando")
    @classmethod
    def validar_comando(cls, v: str) -> str:
        if v not in COMANDOS_VALIDOS:
            raise ValueError(f"Comando inválido. Use: {COMANDOS_VALIDOS}")
        return v


class ComandoResponse(ModeloImutavel):
    """Confirmação de que o comando foi publicado."""
    sucesso: bool
    mensagem: str
    comando: str
