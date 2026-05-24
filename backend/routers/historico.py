# routers/historico.py
# Rota: GET /historico
# Retorna o histórico diário, com filtro opcional por período.

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from models import HistoricoItem
from database import get_supabase
from dependencies import obter_usuario_atual

router = APIRouter(prefix="/historico", tags=["Histórico"])


@router.get("", response_model=List[HistoricoItem])
async def get_historico(
    data_inicio: Optional[str] = Query(None, description="Data inicial YYYY-MM-DD"),
    data_fim:    Optional[str] = Query(None, description="Data final YYYY-MM-DD"),
    usuario: str = Depends(obter_usuario_atual),
):
    """
    Retorna o histórico diário ordenado do mais recente para o mais antigo.

    Filtro opcional por período:
      GET /historico                              → todo o histórico
      GET /historico?data_inicio=2026-05-01       → a partir de uma data
      GET /historico?data_inicio=...&data_fim=... → intervalo fechado

    Controle transacional:
      A query é construída de forma encadeada. Se qualquer parte falhar,
      a exceção é capturada e nenhum dado parcial é retornado.
    """
    try:
        db = get_supabase()

        # Começa com a query base
        query = db.table("historico_diario").select("*").order("data", desc=True)

        # Adiciona filtros condicionalmente (sem alterar objetos existentes)
        if data_inicio:
            query = query.gte("data", data_inicio)
        if data_fim:
            query = query.lte("data", data_fim)

        resultado = query.execute()

        return [
            HistoricoItem(
                id=item["id"],
                data=item.get("data"),
                total_pecas=item["total_pecas"],
                tempo_parado_seg=item["tempo_parado_seg"],
                total_alertas=item["total_alertas"],
                criado_em=item.get("criado_em"),
            )
            for item in resultado.data
        ]

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao consultar histórico: {e}")
