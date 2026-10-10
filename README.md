# LLM Lab

A small, reproducible homelab for learning how to run a local LLM and expose it through a reusable HTTP API. The lab starts with minimal components and adds complexity one phase at a time.

## Current architecture

```text
Client (curl / HTTP client)
        |
        | POST /chat
        v
AI Service (FastAPI, port 8000)
        |
        | POST /api/generate
        v
Ollama (port 11434)
        |
        v
Qwen 2.5 3B
```

Project code stays on the host in Git and is shared with the VM through Vagrant at `/vagrant`. The Python virtual environment lives inside the VM, outside `/vagrant`, to avoid issues with shared folders.

## Status

- [x] Phase 1: Ubuntu VM with Ollama and Qwen 2.5 3B
- [x] Verify Ollama's HTTP API
- [x] Phase 2: FastAPI AI Service calling Ollama
- [x] Verify `GET /health` and `POST /chat`
- [ ] Phase 3: Containerize the AI Service while keeping Ollama on the VM
- [ ] Later: optional embeddings/RAG, integration with other services, Kubernetes, CI/CD, and observability

## Requirements

For a fresh setup:

- Linux, macOS, or Windows with virtualization enabled
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://developer.hashicorp.com/vagrant)
- Git
- Internet access for the VM image, Python packages, and model download
- Recommended: at least 8 GB RAM available for the VM and around 30 GB free disk space

The current `Vagrantfile` allocates **8 GB RAM**, **4 vCPUs**, and private IP **`192.168.56.30`**. Adjust it if your host has fewer resources.

## Repository layout

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

## Phase 1 — Create the VM and install Ollama

From the repository root on the host:

```bash
vagrant up
vagrant ssh
```

The VM uses Ubuntu 22.04 (`ubuntu/jammy64`). Its project directory should be available at `/vagrant`.

Make sure the synced folder is enabled in `Vagrantfile`:

```ruby
config.vm.synced_folder ".", "/vagrant"
```

Do not set `disabled: true`. After changing `Vagrantfile`, apply the change with:

```bash
vagrant reload
```

Inside the VM, verify the files:

```bash
ls -la /vagrant
ls -la /vagrant/ai-service
```

Check Ollama and the model:

```bash
ollama --version
ollama list
```

If `qwen2.5:3b` is missing:

```bash
ollama pull qwen2.5:3b
ollama list
```

Test the API:

```bash
curl http://localhost:11434/api/tags
```

```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5:3b",
    "prompt": "Explain what a Kubernetes pod is in one sentence.",
    "stream": false
  }'
```

The response should be JSON containing a `response` field.

**Troubleshooting:** If `/api/tags` returns `{"models":[]}`, the API is responding but that Ollama instance has no models in its current model store. Check `ollama list` and `sudo systemctl status ollama --no-pager`. Pull the model for the appropriate Ollama user, then verify the list again.

## Phase 2 — Run the FastAPI AI Service

The service exposes:

- `GET /health` — health check
- `POST /chat` — sends a prompt to Ollama and returns the model response

### 1. Install Python venv support

Inside the VM:

```bash
sudo apt update
sudo apt install -y python3-venv
```

On Ubuntu images using Python 3.10, `python3.10-venv` is also a valid package name.

### 2. Create and activate the virtual environment

Do **not** use `sudo` to create it. Keep it outside `/vagrant`, because that is a shared folder.

```bash
python3 -m venv ~/.venvs/ai-service
source ~/.venvs/ai-service/bin/activate
```

If a failed attempt left an incomplete environment:

```bash
rm -rf ~/.venvs/ai-service
python3 -m venv ~/.venvs/ai-service
source ~/.venvs/ai-service/bin/activate
```

### 3. Install dependencies

With the virtual environment activated:

```bash
python -m pip install --upgrade pip
pip install -r /vagrant/ai-service/requirements.txt
```

### 4. Start the API

```bash
cd /vagrant/ai-service
uvicorn main:app --host 0.0.0.0 --port 8000
```

Keep this terminal open while testing.

### 5. Test from a second terminal

On the host, open another terminal and run:

```bash
vagrant ssh
```

Health check:

```bash
curl http://localhost:8000/health
```

Expected:

```json
{"status":"UP"}
```

Chat request:

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Explain what a Kubernetes pod is in one sentence."}'
```

Expected response shape:

```json
{
  "model": "qwen2.5:3b",
  "response": "..."
}
```

You can also open these URLs from the host browser:

- Swagger UI: `http://192.168.56.30:8000/docs`
- OpenAPI schema: `http://192.168.56.30:8000/openapi.json`

### Configuration

| Variable | Default | Purpose |
|---|---|---|
| `OLLAMA_URL` | `http://localhost:11434` | Base URL for Ollama |
| `OLLAMA_MODEL` | `qwen2.5:3b` | Model to request |

When FastAPI runs directly in the VM, `localhost:11434` points to Ollama on that same VM.

### Troubleshooting

**`Could not reach Ollama` or HTTP 404**
1. Run `curl http://localhost:11434/api/tags`.
2. Confirm the model with `ollama list`.
3. Test `/api/generate` directly before debugging FastAPI.
4. If the model list is empty, run `ollama pull qwen2.5:3b` and check again.

**Connection refused on port 8000**
The FastAPI process is not running or not listening on that port. Start it with the `uvicorn` command and leave that terminal open.

**`/vagrant/ai-service` does not exist**
Confirm the synced-folder line in `Vagrantfile` is enabled, then run `vagrant reload`.

## Phase 3 — Containerize the AI Service

Next, create a Dockerfile for FastAPI and run the application in a container. **Ollama will remain installed on the VM** for this phase so we can focus on container networking without running two copies of the model runtime.

Do not assume `localhost` inside the container means the VM host; we will configure the connection to Ollama explicitly in the next phase.

## Learning principles

- Keep the AI Service independent and reusable by other labs.
- Change one layer at a time and test it before moving on.
- Keep inference local for this initial lab.
- Avoid Kubernetes, RAG, vector databases, and other components until they serve a clear learning goal.
