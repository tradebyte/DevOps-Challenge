SHELL := /usr/bin/env bash

.PHONY: setup deploy test smoke-test status destroy fmt validate

setup:
	./scripts/bootstrap.sh

deploy:
	./scripts/local-deploy.sh

test:
	python3 tests/test.py

smoke-test:
	./scripts/smoke-test.sh

status:
	./scripts/status.sh

fmt:
	terraform -chdir=infra/terraform fmt -recursive

validate:
	cd infra && terragrunt init -backend=false && terragrunt validate

destroy:
	./scripts/destroy.sh
