# LLM Lab

Laboratório para aprender LLMs localmente e, posteriormente, integrar IA ao projeto de microservices.

O projeto é desenvolvido em fases pequenas para que cada componente possa ser reutilizado em outros labs.

## Arquitetura atual

```text
Host
 |
 +-- Vagrant
      |
      +-- Ubuntu VM
           |
           +-- Ollama
           |    |
           |    +-- Qwen 2.5 3B
           |
           +-- AI Service (Fase 2)
                |
                +-- FastAPI
                |
                +-- HTTP -> Ollama
```

## Requisitos

Para começar do zero:

- Linux, macOS ou Windows
- VirtualBox
- Vagrant
- Git
- pelo menos 8 GB de RAM disponíveis para a VM
- aproximadamente 30 GB de espaço livre em disco
- Internet na primeira execução para baixar a box e o modelo

A Fase 1 não requer GPU.

## Fase 1 — LLM local

```bash
vagrant up
vagrant ssh
ollama --version
ollama list
ollama run qwen2.5:3b
```

### Testar a API do Ollama

Dentro da VM:

```bash
curl http://localhost:11434/api/generate   -d '{
    "model": "qwen2.5:3b",
    "prompt": "Explain what a Kubernetes pod is in one sentence.",
    "stream": false
  }'
```

Se retornar JSON contendo `response`, a Fase 1 está funcionando.

## Fase 2 — AI Service

Agora criamos um microserviço Python/FastAPI que abstrai o Ollama:

```text
Client
  |
  | POST /chat
  v
AI Service
  |
  | POST /api/generate
  v
Ollama
  |
  v
Qwen 2.5 3B
```

### Instalação

Dentro da VM:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv
```

A partir da raiz do projeto:

```bash
cd ai-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Inicie o serviço:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Testar

Health check:

```bash
curl http://localhost:8000/health
```

Resultado:

```json
{"status":"UP"}
```

Chamar a LLM através do AI Service:

```bash
curl -X POST http://localhost:8000/chat   -H "Content-Type: application/json"   -d '{
    "prompt": "Explain what a Kubernetes pod is in one sentence."
  }'
```

Resultado esperado:

```json
{
  "model": "qwen2.5:3b",
  "response": "..."
}
```

Swagger:

```text
http://192.168.56.30:8000/docs
```

## Configuração

Valores padrão:

```text
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=qwen2.5:3b
```

Podem ser alterados por variáveis de ambiente:

```bash
export OLLAMA_URL=http://localhost:11434
export OLLAMA_MODEL=qwen2.5:3b
```

## Estrutura

```text
llm_lab/
├── Vagrantfile
├── README.md
├── scripts/
│   └── setup.sh
└── ai-service/
    ├── main.py
    └── requirements.txt
```

## Roadmap

- [x] Fase 1 — VM + Ollama + modelo local
- [x] Teste direto da API do Ollama
- [ ] Fase 2 — AI Service com FastAPI
- [ ] Containerizar AI Service
- [ ] RAG
- [ ] Embeddings
- [ ] Vector database
- [ ] Integração com microservices
- [ ] Kubernetes
- [ ] GitHub Actions
- [ ] Argo CD
- [ ] Observabilidade
- [ ] Evolução para arquitetura de AI/MLOps

## Princípios

- começar com o mínimo de infraestrutura;
- separar componentes reutilizáveis;
- evitar Kubernetes até existir uma razão para utilizá-lo;
- entender cada camada antes de adicionar outra;
- manter o AI Service independente para reutilização em outros projetos.
