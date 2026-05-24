# routers/relatorios.py
# Rota: GET /relatorios
# Calcula agregações sobre o histórico diário: média, máx, mín, total.

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional
from models import RelatorioResponse
from database import get_supabase
from dependencies import obter_usuario_atual

router = APIRouter(prefix="/relatorios", tags=["Relatórios"])


@router.get("", response_model=RelatorioResponse)
async def get_relatorios(
    data_inicio: Optional[str] = Query(None, description="Data inicial YYYY-MM-DD"),
    data_fim:    Optional[str] = Query(None, description="Data final YYYY-MM-DD"),
    usuario: str = Depends(obter_usuario_atual),
):
    """
    Retorna agregações calculadas sobre o histórico diário.
    Aceita o mesmo filtro de período que /historico.

    As agregações são feitas em Python sobre os dados retornados.
    Em um sistema maior, seriam feitas diretamente no SQL (mais eficiente),
    mas para este projeto a abordagem em Python é mais legível e fácil de
    explicar na apresentação.
    """
    try:
        db = get_supabase()

        query = db.table("historico_diario").select(
            "total_pecas, tempo_parado_seg, total_alertas"
        )

        if data_inicio:
            query = query.gte("data", data_inicio)
        if data_fim:
            query = query.lte("data", data_fim)

        resultado = query.execute()

        if not resultado.data:
            # Sem dados no período: retorna zeros
            return RelatorioResponse(
                media_pecas=0.0,
                maximo_pecas=0,
                minimo_pecas=0,
                total_dias=0,
                media_tempo_parado_seg=0.0,
                total_alertas=0,
            )

        pecas        = [item["total_pecas"]      for item in resultado.data]
        tempos       = [item["tempo_parado_seg"]  for item in resultado.data]
        alertas_list = [item["total_alertas"]     for item in resultado.data]
        n            = len(pecas)

        return RelatorioResponse(
            media_pecas=round(sum(pecas) / n, 2),
            maximo_pecas=max(pecas),
            minimo_pecas=min(pecas),
            total_dias=n,
            media_tempo_parado_seg=round(sum(tempos) / n, 2),
            total_alertas=sum(alertas_list),
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar relatório: {e}")
