# database.py
# Responsável pela conexão com o Supabase.
# Usa o padrão Singleton: uma única instância do cliente é criada
# e reutilizada em toda a aplicação — evita abrir múltiplas conexões.

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

_supabase_client: Client | None = None


def get_supabase() -> Client:
    """
    Retorna a instância única do cliente Supabase (Singleton).
    Se ainda não foi criada, cria agora. Nas chamadas seguintes,
    reutiliza a mesma instância.
    """
    global _supabase_client

    if _supabase_client is None:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")

        if not url or not key:
            raise RuntimeError(
                "SUPABASE_URL e SUPABASE_KEY precisam estar definidos no .env"
            )

        _supabase_client = create_client(url, key)

    return _supabase_client
