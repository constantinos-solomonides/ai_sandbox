.PHONY: status gemini

STARTED=/tmp/started.state
CREATED=/tmp/created.state
SETUP=/tmp/setup.done
GEMINI_CONFIG=persist/.gemini
WORKSPACE=persist/workspace

status:
	docker compose ps

$(GEMINI_CONFIG):
	mkdir -p $(GEMINI_CONFIG)

$(WORKSPACE):
	mkdir -p $(WORKSPACE)

$(SETUP): $(GEMINI_CONFIG) $(WORKSPACE)
	cp -r ./configuration/gemini/* $(GEMINI_CONFIG)
	touch $(SETUP)

$(CREATED):  $(SETUP)
	docker compose up -d --build
	touch $(CREATED)

down:
	docker compose down -v
	rm -f $(STARTED)
	rm -f $(CREATED)
	rm -f $(SETUP)

$(STARTED): $(CREATED)
	docker compose start
	touch $(STARTED)

stop:
	docker compose stop
	rm -f $(STARTED)

gemini: $(CREATED)
	docker compose exec -it gemini /bin/bash
	# This is needed because the setup may be modified by the container. So the guardrails MUST be updated to remain
	# newer than it
	touch $(WORKSPACE) $(GEMINI_CONFIG) $(SETUP) $(CREATED)

testbox: $(CREATED)
	docker compose exec -it testbox /bin/bash
	# This is needed because the setup may be modified by the container. So the guardrails MUST be updated to remain
	# newer than it
	touch $(WORKSPACE) $(GEMINI_CONFIG) $(SETUP) $(CREATED)
