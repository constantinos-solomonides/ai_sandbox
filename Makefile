.PHONY: status gemini

STARTED=/tmp/started.state
CREATED=/tmp/created.state
SETUP_GEMINI=/tmp/gemini_setup.done
SETUP_CURSOR=/tmp/cursor_setup.done
GEMINI_CONFIG=persist/.gemini
CURSOR_CONFIG=persist/.cursor
WORKSPACE=persist/workspace
CURSOR_RULES=.cursor/rules

status:
	docker compose ps

$(GEMINI_CONFIG) $(CURSOR_CONFIG):
	mkdir -p $@

$(WORKSPACE) $(WORKSPACE)/$(CURSOR_RULES):
	mkdir -p $@

$(SETUP_GEMINI): $(GEMINI_CONFIG) $(WORKSPACE)
	cp -r ./configuration/gemini/* $(GEMINI_CONFIG)
	touch $@

$(SETUP_CURSOR): $(CURSOR_CONFIG) $(WORKSPACE)/$(CURSOR_RULES)
	cp -r ./configuration/cursor/* $(CURSOR_CONFIG)
	cp -r ./AI.md $(CURSOR_CONFIG)/ris.mdc
	touch $@

$(CREATED):  $(SETUP_GEMINI) $(SETUP_CURSOR)
	docker compose up -d --build
	touch $@

down:
	docker compose down -v
	rm -f $(STARTED)
	rm -f $(CREATED)
	rm -f $(SETUP_GEMINI)
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
	touch $(WORKSPACE) $(GEMINI_CONFIG) $(SETUP_GEMINI) $(SETUP_CURSOR) $(CREATED)

testbox: $(CREATED) $(CURSOR_CONFIG)
	docker compose exec -it testbox /bin/bash
	# This is needed because the setup may be modified by the container. So the guardrails MUST be updated to remain
	# newer than it
	touch $(WORKSPACE) $(GEMINI_CONFIG) $(SETUP_GEMINI) $(SETUP_CURSOR) $(CREATED)
