# mqtt_service.py
# Responsável por publicar mensagens no broker MQTT (HiveMQ).
#
# Ciclo de vida da thread:
#   O paho-mqtt usa uma thread interna (loop_start) para manter a
#   conexão viva em background. Quando publicamos, a mensagem é
#   enfileirada e enviada por essa thread, sem bloquear a thread
#   principal da API (a que está atendendo a requisição HTTP).
#   Isso é a "comunicação assíncrona" entre a API e o ESP32.

import os
import paho.mqtt.client as mqtt
from dotenv import load_dotenv

load_dotenv()

BROKER = os.getenv("MQTT_BROKER", "broker.hivemq.com")
PORT   = int(os.getenv("MQTT_PORT", 1883))
TOPIC  = os.getenv("MQTT_TOPIC_COMANDO", "fabrica/linha1/comando")


def publicar_comando(comando: str) -> bool:
    """
    Conecta ao broker HiveMQ, publica o comando no tópico de controle
    do ESP32 e desconecta em seguida.

    Retorna True se publicado com sucesso, False em caso de erro.

    Por que conectar e desconectar a cada chamada?
    Para um backend que não precisa receber mensagens (só publicar),
    essa abordagem é mais simples e robusta: sem estado de conexão
    para gerenciar, sem reconexões automáticas para monitorar.
    """
    try:
        client = mqtt.Client(client_id="fastapi_backend", clean_session=True)

        # Conecta de forma síncrona (aguarda confirmação do broker)
        client.connect(BROKER, PORT, keepalive=10)

        # Inicia a thread interna do paho para processar a fila de envio
        client.loop_start()

        # Publica com QoS 1: o broker confirma o recebimento
        result = client.publish(TOPIC, comando, qos=1)

        # Aguarda até a mensagem ser confirmada (máx. 3 segundos)
        result.wait_for_publish(timeout=3)

        client.loop_stop()
        client.disconnect()

        return True

    except Exception as e:
        print(f"[MQTT] Erro ao publicar '{comando}': {e}")
        return False
