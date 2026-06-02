SHELL := /bin/bash
HOST_PORT ?= 8080

.PHONY: setup up down test

setup:
	@echo "Cloning sibling repos as local build contexts..."
	@if [ ! -d db/.git ]; then git clone https://github.com/duganbrettc/cascade-xclone-v34q-db.git db; else git -C db pull; fi
	@if [ ! -d api/.git ]; then git clone https://github.com/duganbrettc/cascade-xclone-v34q-api.git api; else git -C api pull; fi
	@if [ ! -d web/.git ]; then git clone https://github.com/duganbrettc/cascade-xclone-v34q-web.git web; else git -C web pull; fi

up: setup
	HOST_PORT=$(HOST_PORT) docker compose up -d --build

down:
	docker compose down -v

test:
	HOST_PORT=$(HOST_PORT) BASE_URL=http://localhost:$(HOST_PORT) bash acceptance/probe.sh
