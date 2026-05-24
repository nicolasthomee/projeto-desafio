# routers/producao.py
# Rota: GET /producao
# Retorna o registro mais recente da tabela 'producao'.
# O Flutter chama isso a cada 5 segundos para simular tempo real (polling).

from fastapi import APIRouter, Depends, HTTPException
from models import ProducaoItem
from database import get_supabase
from dependencies import obter_usuario_atual

router = APIRouter(prefix="/producao", tags=["Produção"])


@router.get("", response_model=ProducaoItem)
async def get_producao_atual(usuario: str = Depends(obter_usuario_atual)):
    """
    Retorna o registro mais recente da tabela producao.

    Rota protegida: requer JWT válido no header Authorization.

    O Node-RED insere um novo registro a cada mensagem MQTT recebida.
    Pegamos o mais recente ordenando por id decrescente e limitando a 1.
    """
    try:
        db = get_supabase()
        resultado = (
            db.table("producao")
            .select("*")
            .order("id", desc=True)
            .limit(1)
            .execute()
        )

        if not resultado.data:
            raise HTTPException(status_code=404, detail="Nenhum dado de produção encontrado")

        item = resultado.data[0]
        return ProducaoItem(
            id=item["id"],
            contador=item["contador"],
            status=item["status"],
            alerta=item["alerta"],
            tempo_parado=item["tempo_parado"],
            criado_em=item.get("criado_em"),
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao consultar produção: {e}")
