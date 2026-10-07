# LLM Lab - Fase 1

Lab mínimo para aprender LLM localmente usando Vagrant + VirtualBox + Ubuntu + Docker + Ollama.

## Requisitos

- VirtualBox
- Vagrant
- CPU com virtualização habilitada
- Pelo menos ~10 GB de RAM disponíveis para a VM durante o lab
- Internet para baixar a box, Docker e o modelo

## Criar a VM

```bash
vagrant up
```

A VM terá:

- 4 vCPU
- 8 GB RAM
- IP `192.168.56.30`
- Ubuntu 22.04
- Docker
- Ollama
- modelo `qwen2.5:3b`

## Acessar

```bash
vagrant ssh
```

## Testar Ollama

```bash
curl http://localhost:11434/api/tags
```

Teste uma geração:

```bash
curl http://localhost:11434/api/generate \\
  -d '{"model":"qwen2.5:3b","prompt":"Explain Kubernetes in one sentence.","stream":false}'
```

## Testar do host

```bash
curl http://192.168.56.30:11434/api/tags
```

## Parar a VM

```bash
vagrant halt
```

## Destruir a VM

```bash
vagrant destroy -f
```

## Próxima evolução

Depois desta fase, o próximo passo pode ser adicionar um pequeno `AI Service` em Python/FastAPI que consuma a API do Ollama. Esse serviço poderá posteriormente ser extraído/reutilizado como um microserviço independente no projeto Monolith → Microservices.
# llm_lab
# llm_lab
# llm_lab
