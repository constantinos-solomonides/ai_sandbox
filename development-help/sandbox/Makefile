.PHONY: status up down start stop gemini

status:
	docker compose ps

up:
	docker compose up -d

down:
	docker compose down -v

start:
	docker compose start

stop:
	docker compose stop

gemini: up
	docker compose exec -it gemini /bin/bash
