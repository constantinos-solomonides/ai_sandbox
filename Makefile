.PHONY: status gemini

STARTED=/tmp/started.state
CREATED=/tmp/created.state
GEMINI_CONFIG=persist/.gemini
WORKSPACE=persist/workspace

status:
	docker compose ps

$(GEMINI_CONFIG):
	mkdir -p $(GEMINI_CONFIG)

$(WORKSPACE):
	mkdir -p $(WORKSPACE)

setup: $(GEMINI_CONFIG) $(WORKSPACE)
	cp -r ./configuration/gemini/* $(GEMINI_CONFIG)

$(STARTED):
	touch $(STARTED)

$(CREATED):
	touch $(CREATED)

up: $(STARTED) $(CREATED) setup
	docker compose up -d

down:
	docker compose down -v
	rm -f $(STARTED)
	rm -f $(CREATED)

start: up $(STARTED)
	docker compose start

stop:
	docker compose stop
	rm -f $(STARTED)

gemini: up
	docker compose exec -it gemini /bin/bash

testbox: up
	docker compose exec -it testbox /bin/bash
