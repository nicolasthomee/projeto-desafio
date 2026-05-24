# Sistema IoT - Monitoramento de Produção Industrial

Aplicativo mobile Flutter integrado a um ESP32 para monitoramento em tempo real de uma linha de produção industrial.

## Arquitetura do Sistema

```
ESP32 (Sensor IR + Botão)
    │
    │  MQTT (HiveMQ público — broker.hivemq.com:1883)
    ▼
Node-RED (notebook)
    │  Assina todos os tópicos MQTT e salva no banco
    ▼
Supabase (PostgreSQL na nuvem)
    │
    │  HTTP REST
    ▼
FastAPI (notebook — porta 8000)
    │  API REST própria com autenticação JWT
    ▼
Flutter (app mobile)
```

## Fluxo de Dados

1. O ESP32 detecta peças via sensor IR e publica no tópico `fabrica/linha1/contador`
2. O Node-RED recebe a mensagem MQTT e insere na tabela `producao` do Supabase
3. O Flutter chama `GET /producao` a cada 5 segundos (polling) para exibir os dados em tempo real
4. Para enviar comandos, o Flutter faz `POST /comando` → a FastAPI publica no tópico MQTT → o ESP32 executa

---

## Configuração e Execução

### 1. Banco de Dados (Supabase)

O banco já está configurado em: `https://tpgmrkxguxwgyaarvwlw.supabase.co`

Tabelas necessárias:
- `producao` — registros em tempo real
- `historico_diario` — resumo por expediente
- `alertas` — log de alertas
- `usuarios` — autenticação

### 2. Node-RED

Importe o flow do arquivo `nodered_flow.json` (se disponível) ou configure manualmente:
- Subscribe nos tópicos `fabrica/linha1/#`
- Salve cada mensagem na tabela correspondente do Supabase via HTTP request

### 3. Backend (FastAPI)

**Pré-requisitos:** Python 3.11+

```bash
cd backend
pip install -r requirements.txt
```

Configure o arquivo `.env`:
```env
SUPABASE_URL=https://tpgmrkxguxwgyaarvwlw.supabase.co
SUPABASE_KEY=sua_chave_aqui
SECRET_KEY=sua_chave_jwt_secreta
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
MQTT_BROKER=broker.hivemq.com
MQTT_PORT=1883
MQTT_TOPIC_COMANDO=fabrica/linha1/comando
```

Inicie a API:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Acesse a documentação interativa: `http://localhost:8000/docs`

### 4. Flutter

**Pré-requisitos:** Flutter 3.19+

Edite `lib/services/api_service.dart` e troque o `BASE_URL` pelo IP do notebook:
```dart
static const String BASE_URL = 'http://SEU_IP_AQUI:8000';
```

Para descobrir o IP do notebook: abra o terminal e execute `ipconfig` (Windows) ou `ifconfig` (Linux/Mac).

```bash
cd app_integrador
flutter pub get
flutter run
```

### 5. ESP32

- Abra o arquivo `esp32/main.ino` no Arduino IDE
- Configure o SSID e senha do WiFi no código
- Faça o upload para o ESP32

---

## Endpoints da API

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| GET | `/` | Health check | Não |
| POST | `/auth/cadastro` | Criar novo usuário | Não |
| POST | `/auth/login` | Login → retorna JWT | Não |
| GET | `/producao` | Último registro em tempo real | JWT |
| GET | `/historico` | Histórico diário completo | JWT |
| GET | `/historico?data_inicio=&data_fim=` | Histórico filtrado por período | JWT |
| GET | `/relatorios` | Agregações (média, máx, mín) | JWT |
| GET | `/relatorios?data_inicio=&data_fim=` | Relatório por período | JWT |
| POST | `/comando` | Enviar comando ao ESP32 | JWT |

---

## Telas do Aplicativo

| # | Tela | Descrição |
|---|------|-----------|
| 1 | Login | Autenticação com e-mail e senha |
| 2 | Cadastro | Criação de nova conta |
| 3 | Dashboard | Dados em tempo real (polling 5s): contador, status, tempo parado |
| 4 | Controle | Botões para enviar comandos ao ESP32 |
| 5 | Histórico | Lista e gráfico de produção por dia |
| 6 | Relatórios | Médias, máximo, mínimo e total de alertas por período |

---

## Decisões Arquiteturais

### Por que FastAPI?
- Suporte nativo a `async/await` — não bloqueia a thread enquanto espera resposta do banco ou do MQTT
- Validação automática de dados via Pydantic
- Documentação interativa gerada automaticamente (`/docs`)

### Por que modelos imutáveis (sem setters)?
- Garante que os dados não sejam alterados acidentalmente após criação
- Em Flutter: campos `final` + construtor `const`
- Na API: Pydantic com `frozen=True`
- Facilita rastreamento de bugs — o estado só muda em pontos explícitos

### Controle transacional
- No cadastro: verificação de duplicata → inserção em sequência. Se a inserção falha, o erro é propagado e nenhum dado parcial fica salvo
- Tratamento de exceções em todas as camadas (IoT → API → Flutter)

### Ciclo de vida da thread
- **FastAPI**: endpoints `async def` liberam a thread do servidor enquanto aguardam I/O (banco, MQTT)
- **Flutter**: `async/await` com `Future` — a UI thread nunca é bloqueada. O polling usa `Timer.periodic` que dispara na UI thread mas suspende a chamada HTTP sem travar a interface
- **MQTT**: o paho-mqtt usa uma thread interna (`loop_start`) para processar a fila de mensagens em background

---

## Diagrama Lógico do Banco de Dados

```
usuarios
├── id (PK)
├── email (UNIQUE)
├── senha_hash
└── criado_em

producao
├── id (PK)
├── contador      ← total de peças no momento
├── status        ← RODANDO | PARADA | ALERTA | STANDBY | ENCERRADO
├── alerta        ← NORMAL | SEM_PRODUCAO | STANDBY
├── tempo_parado  ← segundos acumulados
└── criado_em

historico_diario
├── id (PK)
├── data          ← data do expediente
├── total_pecas
├── tempo_parado_seg
├── total_alertas
└── criado_em

alertas
├── id (PK)
├── tipo
├── status
└── criado_em
```

### Regras de Negócio
- Um registro em `producao` é inserido a cada mensagem MQTT recebida pelo Node-RED
- Um registro em `historico_diario` é inserido apenas quando o comando `FECHAR_DIA` é executado no ESP32
- O campo `alerta` na tabela `producao` reflete o estado atual: `NORMAL` quando rodando, `SEM_PRODUCAO` quando o sensor não detecta peças por mais de 10 segundos
- Usuários são autenticados via JWT com expiração de 60 minutos

---

## Integrantes do Grupo

| Nome | Função |
|------|--------|
| [Nome 1] | Flutter (UI + Providers) |
| [Nome 2] | Backend (FastAPI + MQTT) |
| [Nome 3] | ESP32 + Node-RED |
| [Nome 4] | Documentação + Banco de Dados |
