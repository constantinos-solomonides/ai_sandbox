.PHONY: up down pull-model logs exec clean status setup configs

status:
	docker compose ps

configs:
	mkdir -p persist/workspace
	mkdir -p persist/opencode-config/
	cp --update configuration/opencode/opencode.json -T persist/opencode-config/opencode.json

setup: configs ollama opencode
	:


testbox-setup:
	docker compose
opencode: pull-model
	docker compose up -d opencode

gemini-up:
	docker compose up -d gemini

gemini: gemini-up
	docker compose exec -it gemini /bin/bash

ollama:
	docker compose up -d ollama
	docker compose exec ollama /bin/bash -c 'apt-get update; apt-get install -y curl'
	@echo "Waiting for Ollama to be healthy..."
	@sleep 5
	@docker compose ps

down:
	docker compose down

logs:
	docker compose logs -f ollama

clean:
	docker compose down -v
	@echo "Volumes deleted. Models will need to be re-pulled."
