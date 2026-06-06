# Sistema IoT - Monitoramento de Produção Industrial

Aplicativo mobile Flutter integrado a um ESP32 para monitoramento em tempo real de uma linha de produção industrial. Interface dark industrial com paleta monocromática (fundo escuro + accent ciano), tipografia JetBrains Mono e Space Grotesk.

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
    │  API REST com autenticação JWT
    ▼
Flutter (app mobile — Android/iOS)
```

## Fluxo de Dados

1. O ESP32 detecta peças via sensor IR e publica no tópico `fabrica/linha1/contador`
2. O Node-RED recebe a mensagem MQTT e insere na tabela `producao` do Supabase
3. O Flutter consulta `GET /producao` a cada 5 segundos (polling) para exibir dados em tempo real
4. Para enviar comandos: Flutter faz `POST /comando` → FastAPI publica no tópico MQTT → ESP32 executa

---

## Configuração e Execução

### 1. Banco de Dados (Supabase)

O banco já está configurado em: `https://tpgmrkxguxwgyaarvwlw.supabase.co`

Tabelas necessárias:
- `producao` — registros em tempo real do ESP32
- `historico_diario` — resumo por expediente (fechado via comando)
- `alertas` — log de eventos de alerta
- `usuarios` — autenticação de usuários

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
SUPABASE_KEY=sua_chave_service_role_aqui   # chave JWT que começa com eyJ...
SECRET_KEY=sua_chave_jwt_secreta
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
MQTT_BROKER=broker.hivemq.com
MQTT_PORT=1883
MQTT_TOPIC_COMANDO=fabrica/linha1/comando
```

> **Importante:** `SUPABASE_KEY` deve ser a chave `service_role` (JWT começando com `eyJ`), obtida em Supabase → Project Settings → API.

Inicie a API (acessível na rede local):
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Documentação interativa: `http://localhost:8000/docs`

### 4. Flutter

**Pré-requisitos:** Flutter 3.19+

Edite `app_integrador/lib/services/api_service.dart` e troque o `baseUrl` pelo IP do notebook:
```dart
static const String baseUrl = 'http://SEU_IP_AQUI:8000';
```

Para descobrir o IP: execute `ipconfig` (Windows) ou `ifconfig` (Linux/Mac) no terminal.

```bash
cd app_integrador
flutter pub get
flutter run
```

### 5. ESP32

- Abra `esp32/main.ino` no Arduino IDE
- Configure o SSID e senha do WiFi no código
- Faça o upload para o ESP32

---

## Endpoints da API

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| GET | `/` | Health check | Não |
| POST | `/auth/cadastro` | Criar novo usuário | Não |
| POST | `/auth/login` | Login — retorna JWT | Não |
| GET | `/producao` | Último registro em tempo real | JWT |
| GET | `/historico` | Histórico diário completo | JWT |
| GET | `/historico?data_inicio=&data_fim=` | Histórico filtrado por período | JWT |
| GET | `/relatorios` | Agregações (média, máx, mín) | JWT |
| GET | `/relatorios?data_inicio=&data_fim=` | Relatório por período | JWT |
| POST | `/comando` | Enviar comando ao ESP32 via MQTT | JWT |

---

## Telas do Aplicativo

| # | Tela | Descrição |
|---|------|-----------|
| 1 | Login | Autenticação com e-mail e senha, card dark com glow accent |
| 2 | Cadastro | Criação de nova conta |
| 3 | Dashboard | Polling 5s — painel de status industrial (LED + borda colorida), contador de peças, tempo parado |
| 4 | Controle | Botões para enviar comandos ao ESP32 (INICIAR, PARAR, STANDBY, FECHAR DIA, LIMPAR) |
| 5 | Histórico | Gráfico de barras 7 dias + lista de registros diários |
| 6 | Relatórios | Média, máximo, mínimo, total de alertas e tempo médio parado — filtro por período |

---

## Design

Interface dark industrial com exatamente 3 camadas de cor:

| Camada | Uso | Cor |
|--------|-----|-----|
| Escuro | Fundos, cards, bordas | `#0D1117` → `#30363D` |
| Claro | Texto primário e secundário | `#E6EDF3`, `#8B949E` |
| Ciano | Accent — tudo interativo e em destaque | `#00D9FF` |

- **JetBrains Mono** — números e dados (estilo terminal/instrumentação)
- **Space Grotesk** — títulos, labels e texto corrido

Status da linha comunicado por intensidade do accent (100% ativo / 50% standby / 20% parado) + ícone + borda esquerda colorida no painel.

---

## Decisões Arquiteturais

### Por que FastAPI?
- `async/await` nativo — não bloqueia enquanto espera resposta do banco ou MQTT
- Validação automática de dados via Pydantic
- Documentação interativa gerada automaticamente em `/docs`

### Por que modelos imutáveis?
- Campos `final` no Flutter e `frozen=True` no Pydantic
- Estado só muda em pontos explícitos — facilita rastreamento de bugs

### Ciclo de vida assíncrono
- **FastAPI**: endpoints `async def` liberam a thread do servidor durante I/O
- **Flutter**: `Timer.periodic` para polling — dispara na UI thread mas suspende a chamada HTTP sem travar a interface
- **MQTT**: paho-mqtt usa thread interna (`loop_start`) para processar fila em background; `client_id` único por conexão (UUID) evita conflitos no broker

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
- Um registro em `historico_diario` é gerado apenas quando o comando `FECHAR_DIA` é executado
- O campo `alerta` reflete o estado atual: `NORMAL` quando rodando, `SEM_PRODUCAO` quando o sensor não detecta peças por mais de 10 segundos
- JWT com expiração de 60 minutos; token armazenado via SharedPreferences no app

---

## Integrantes do Grupo

| Nome | Função |
|------|--------|
| [Nome 1] | Flutter (UI + Providers) |
| [Nome 2] | Backend (FastAPI + MQTT) |
| [Nome 3] | ESP32 + Node-RED |
| [Nome 4] | Documentação + Banco de Dados |
