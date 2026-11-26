SHELL_FILES := $(wildcard $(shell git ls-files --cached --others --exclude-standard '*.sh'))

.PHONY: check lint syntax fmt fmt-check hooks

check: syntax lint fmt-check ## Run all static checks

syntax: ## bash -n parse check
	@for f in $(SHELL_FILES); do bash -n "$$f" || exit 1; done

lint: ## shellcheck
	@shellcheck $(SHELL_FILES)

fmt: ## Format with shfmt
	@shfmt -w $(SHELL_FILES)

fmt-check: ## Verify formatting with shfmt
	@shfmt -d $(SHELL_FILES)

hooks: ## Enable the repo's git hooks
	@git config core.hooksPath .githooks
	@echo "git hooks enabled (.githooks)"
