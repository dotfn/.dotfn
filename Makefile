.PHONY: build up shell stop destroy logs versions

build:
	docker compose build

up:
	docker compose up -d

shell:
	docker compose exec dev zsh

dev: up shell

stop:
	docker compose stop

destroy:
	docker compose down -v

logs:
	docker compose logs -f dev

versions:
	docker compose exec dev zsh -c "node --version && npm --version && git --version && fnm --version && starship --version"
