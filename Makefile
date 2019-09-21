# Configuration
# -------------

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VERSION ?= `grep 'version:' mix.exs | cut -d '"' -f2`
DOCKER_IMAGE_TAG ?= latest
GIT_REVISION ?= `git rev-parse HEAD`

# Introspection targets
# ---------------------

.PHONY: help
help: header targets

.PHONY: header
header:
	@echo -e "\033[34mEnvironment\033[0m"
	@echo -e "\033[34m---------------------------------------------------------------\033[0m"
	@printf "\033[33m%-23s\033[0m" "APP_NAME"
	@printf "\033[35m%s\033[0m" $(APP_NAME)
	@echo ""
	@printf "\033[33m%-23s\033[0m" "APP_VERSION"
	@printf "\033[35m%s\033[0m" $(APP_VERSION)
	@echo ""
	@printf "\033[33m%-23s\033[0m" "GIT_REVISION"
	@printf "\033[35m%s\033[0m" $(GIT_REVISION)
	@echo ""
	@printf "\033[33m%-23s\033[0m" "DOCKER_IMAGE_TAG"
	@printf "\033[35m%s\033[0m" $(DOCKER_IMAGE_TAG)
	@echo "\n"

.PHONY: targets
targets:
	@echo -e "\033[34mTargets\033[0m"
	@echo -e "\033[34m---------------------------------------------------------------\033[0m"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'


.PHONY: lint-compile
lint-compile:
	mix compile --warnings-as-errors --force

.PHONY: lint-format
lint-format:
	mix format --dry-run --check-formatted

.PHONY: lint-credo
lint-credo:
	mix credo --strict

.PHONY: lint
lint: lint-compile lint-format lint-credo


.PHONY: test
test: ## Run the test suite
	mix test

.PHONY: test-coverage
test-coverage: ## Generate the code coverage report
	mix coveralls

.PHONY: format
format: mix format ## Run formatting tools on the code


init:
	chmod -R a+x  .githooks
	git config core.hooksPath .githooks

make_lint_file_executable:
		@chmod a+x check_lint.sh

## running shell script files https://stackoverflow.com/a/2497682
.PHONY: check_lint
check_lint: make_lint_file_executable
	./check_lint.sh


release: ## Build a release of the application with MIX_ENV=prod
	MIX_ENV=prod mix deps.get --only prod
	cd assets && npm i && webpack --mode production
	mkdir -p priv/static
	MIX_ENV=prod mix phx.digest
	MIX_ENV=prod mix release --verbose


release_staging_start_server: release
	@chmod a+x rel/commands/stop_server.sh
	./rel/commands/stop_server.sh
	PORT=8080 _build/prod/rel/vibrant/bin/vibrant start
	PORT=8889 MIX_ENV=prod mix run priv/repo/seeds.exs

release_production_start_server: release
	@chmod a+x rel/commands/stop_server.sh
	./rel/commands/stop_server.sh
	PORT=9000 _build/prod/rel/vibrant/bin/vibrant start
