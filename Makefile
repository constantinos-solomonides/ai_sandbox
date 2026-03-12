.PHONY: status gemini

STARTED=/tmp/ai_sandbox-started.state
CREATED=/tmp/ai_status-created.state
SETUP_CURSOR=/tmp/ai_status-cursor_setup.done

CURSOR_CONFIG=persist/.cursor
WORKSPACE=persist/workspace
CURSOR_RULES=.cursor/rules

status:
	docker compose ps

$(CURSOR_CONFIG):
	mkdir -p $@

$(WORKSPACE):
	mkdir -p $@

$(SETUP_CURSOR): $(CURSOR_CONFIG)
	cp -r ./AI.md $(CURSOR_CONFIG)/ris.mdc
	touch $@

$(CREATED): $(SETUP_CURSOR)
	docker compose up -d --build
	touch $@

$(CURSOR_POST_INSTALL): $(CREATED)

down:
	docker compose down -v
	rm -f $(STARTED)
	rm -f $(CREATED)
	rm -f $(SETUP_CURSOR)

$(STARTED): $(CREATED)
	docker compose start
	touch $@

stop:
	docker compose stop
	rm -f $(STARTED)

gemini: $(CREATED)
	docker compose exec -it gemini /bin/bash
	# This is needed because the setup may be modified by the container. So the guardrails MUST be updated to remain
	# newer than it
	touch $(WORKSPACE) $(GEMINI_CONFIG) $(SETUP_CURSOR) $(CREATED)

testbox: $(CREATED) $(CURSOR_CONFIG)
	docker compose exec -it testbox /bin/bash
	# This is needed because the setup may be modified by the container. So the guardrails MUST be updated to remain
	# newer than it
	touch $(WORKSPACE) $(GEMINI_CONFIG) $(SETUP_CURSOR) $(CREATED)
