# routers/comando.py
# Rota: POST /comando
# Recebe um comando do Flutter e publica no tópico MQTT do ESP32.
#
# Fluxo assíncrono:
#   Flutter → POST /comando (HTTP) → FastAPI → MQTT publish → ESP32
#   A resposta HTTP é enviada ao Flutter assim que o MQTT confirmar
#   o recebimento pelo broker (QoS 1), sem esperar o ESP32 executar.

from fastapi import APIRouter, Depends, HTTPException
from models import ComandoRequest, ComandoResponse
from mqtt_service import publicar_comando
from dependencies import obter_usuario_atual

router = APIRouter(prefix="/comando", tags=["Controle"])


@router.post("", response_model=ComandoResponse)
async def enviar_comando(
    body: ComandoRequest,
    usuario: str = Depends(obter_usuario_atual),
):
    """
    Publica um comando no tópico MQTT fabrica/linha1/comando.

    Comandos aceitos: PAUSAR, RETOMAR, SILENCIAR, RESET, FECHAR_DIA
    (validação feita no modelo ComandoRequest via @field_validator)

    Rota protegida: apenas usuários autenticados podem enviar comandos.
    """
    sucesso = publicar_comando(body.comando)

    if not sucesso:
        raise HTTPException(
            status_code=503,
            detail="Falha ao publicar no broker MQTT. Verifique a conexão de rede.",
        )

    return ComandoResponse(
        sucesso=True,
        mensagem=f"Comando '{body.comando}' enviado com sucesso ao ESP32",
        comando=body.comando,
    )
