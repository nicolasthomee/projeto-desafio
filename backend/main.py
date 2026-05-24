# main.py
# Ponto de entrada da API.
# Registra todos os roteadores e configura o CORS para aceitar
# requisições do Flutter (que roda em IP diferente durante o desenvolvimento).

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import auth, producao, historico, relatorios, comando

app = FastAPI(
    title="API - Monitoramento Industrial IoT",
    description="Backend do sistema de monitoramento de produção com ESP32",
    version="1.0.0",
)

# CORS: permite que o Flutter (qualquer origem em dev) acesse a API.
# Em produção, substituir origins=["*"] pelo IP/domínio real.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registra os roteadores com seus prefixos
app.include_router(auth.router)
app.include_router(producao.router)
app.include_router(historico.router)
app.include_router(relatorios.router)
app.include_router(comando.router)


@app.get("/", tags=["Status"])
async def root():
    """Health check — confirma que a API está no ar."""
    return {"status": "online", "mensagem": "API IoT Monitoramento Industrial"}


# Para rodar: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
