# Makefile - Test infrastructure for safety hooks
# Usage: cd tests && make test

.PHONY: all build test test-unit test-integration test-e2e test-no-llm clean shell lint help

# =============================================================================
# Configuration
# =============================================================================

IMAGE_NAME := agent-discipline-test
CONTAINER_NAME := agent-discipline-test-runner

# Detect container runtime (prefer colima/docker, fall back to podman)
CONTAINER_RUNTIME := $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null)

# Claude credentials path (for E2E tests)
CLAUDE_CREDENTIALS := $(HOME)/.claude/.credentials.json

# =============================================================================
# Default target
# =============================================================================

all: help

# =============================================================================
# Help
# =============================================================================

help: ## Show this help
	@echo "Safety Hooks Test Infrastructure"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make test          # Run all tests (includes E2E with real Claude)"
	@echo "  make test-no-llm   # Run unit/integration only (no API calls)"
	@echo "  make test-e2e      # Run only E2E tests with real Claude"
	@echo "  make shell         # Open shell in container for debugging"

# =============================================================================
# Build
# =============================================================================

build: ## Build the test container image
	@echo "Building test container..."
	$(CONTAINER_RUNTIME) build -t $(IMAGE_NAME) -f Dockerfile.test .

build-no-cache: ## Build the test container without cache
	$(CONTAINER_RUNTIME) build --no-cache -t $(IMAGE_NAME) -f Dockerfile.test .

# =============================================================================
# Test Targets
# =============================================================================

test: build ## Run all tests (default: includes E2E with real Claude Code)
	@echo "Running all tests (including E2E with Claude Code)..."
	@if [ ! -f "$(CLAUDE_CREDENTIALS)" ]; then \
		echo "WARNING: $(CLAUDE_CREDENTIALS) not found"; \
		echo "E2E tests will fail. Run 'make test-no-llm' for unit tests only."; \
	fi
	# Mount architecture:
	# - /fixtures:ro     = Test data, read-only (copied to /working before tests)
	# - /results         = Writable output directory
	# - ~/.claude/hooks  = Safety hooks under test
	# - credentials.json = API auth (read-only)
	# Tests run in /working which is writable inside container
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/results:/results \
		-v $(PWD)/../.claude/hooks:/home/testuser/.claude/hooks:ro \
		-v $(CLAUDE_CREDENTIALS):/home/testuser/.claude/.credentials.json:ro \
		$(IMAGE_NAME) --all

test-no-llm: build ## Run unit and integration tests only (no API calls, fast)
	@echo "Running tests without LLM (unit + integration only)..."
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/results:/results \
		-v $(PWD)/../.claude/hooks:/hooks:ro \
		$(IMAGE_NAME) --no-llm

test-unit: build ## Run unit tests only (pattern matching)
	@echo "Running unit tests..."
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/../.claude/hooks:/hooks:ro \
		$(IMAGE_NAME) --unit --no-llm

test-integration: build ## Run integration tests (hook invocation)
	@echo "Running integration tests..."
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/../.claude/hooks:/hooks:ro \
		$(IMAGE_NAME) --integration --no-llm

test-e2e: build ## Run E2E tests only (real Claude Code, requires API key)
	@echo "Running E2E tests with real Claude Code..."
	@if [ ! -f "$(CLAUDE_CREDENTIALS)" ]; then \
		echo "ERROR: $(CLAUDE_CREDENTIALS) not found"; \
		echo "Please run 'claude' once to authenticate, or set ANTHROPIC_API_KEY"; \
		exit 1; \
	fi
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/results:/results \
		-v $(PWD)/../.claude/hooks:/home/testuser/.claude/hooks:ro \
		-v $(CLAUDE_CREDENTIALS):/home/testuser/.claude/.credentials.json:ro \
		$(IMAGE_NAME) --e2e

test-verbose: build ## Run all tests with verbose output
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-e VERBOSE=1 \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/results:/results \
		-v $(PWD)/../.claude/hooks:/home/testuser/.claude/hooks:ro \
		-v $(CLAUDE_CREDENTIALS):/home/testuser/.claude/.credentials.json:ro \
		$(IMAGE_NAME) --all

# =============================================================================
# Development
# =============================================================================

shell: build ## Open shell in test container for debugging
	$(CONTAINER_RUNTIME) run -it --rm --name $(CONTAINER_NAME) \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/results:/results \
		-v $(PWD)/../.claude/hooks:/home/testuser/.claude/hooks:ro \
		-v $(CLAUDE_CREDENTIALS):/home/testuser/.claude/.credentials.json:ro \
		--entrypoint /bin/bash \
		$(IMAGE_NAME)

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Remove test container and image
	@echo "Cleaning up..."
	-$(CONTAINER_RUNTIME) rm -f $(CONTAINER_NAME) 2>/dev/null || true
	-$(CONTAINER_RUNTIME) rmi $(IMAGE_NAME) 2>/dev/null || true
	rm -rf results/*

clean-results: ## Clear test results only
	rm -rf results/*

# =============================================================================
# Linting
# =============================================================================

lint: ## Lint test scripts with shellcheck
	@echo "Linting shell scripts..."
	@find . -name '*.sh' -type f | xargs shellcheck 2>/dev/null || \
		echo "Note: Install shellcheck for linting (brew install shellcheck)"

# =============================================================================
# Fixture Management
# =============================================================================

setup-fixtures: ## Initialize git and db fixtures (run once)
	@echo "Setting up fixtures..."
	@if [ -f fixtures/git/setup.sh ]; then \
		chmod +x fixtures/git/setup.sh && \
		fixtures/git/setup.sh; \
	fi
	@if [ -f fixtures/db/setup.sql ] && [ ! -f fixtures/db/test.sqlite ]; then \
		sqlite3 fixtures/db/test.sqlite < fixtures/db/setup.sql; \
	fi
	@echo "Fixtures ready."

reset-fixtures: ## Reset fixtures to clean state
	@echo "Resetting fixtures..."
	rm -rf fixtures/git/repo fixtures/git/remote.git fixtures/db/test.sqlite
	$(MAKE) setup-fixtures

# =============================================================================
# CI Integration
# =============================================================================

ci: build ## Run tests for CI (uses ANTHROPIC_API_KEY env var)
	@echo "Running CI test suite..."
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-e ANTHROPIC_API_KEY \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/results:/results \
		-v $(PWD)/../.claude/hooks:/home/testuser/.claude/hooks:ro \
		$(IMAGE_NAME) --all | tee results/test-output.tap
	@echo ""
	@echo "Test output saved to results/test-output.tap"

ci-no-llm: build ## Run CI tests without LLM (for PRs without API access)
	@echo "Running CI test suite (no LLM)..."
	$(CONTAINER_RUNTIME) run --rm --name $(CONTAINER_NAME) \
		-v $(PWD)/fixtures:/fixtures:ro \
		-v $(PWD)/results:/results \
		-v $(PWD)/../.claude/hooks:/hooks:ro \
		$(IMAGE_NAME) --no-llm | tee results/test-output.tap

# =============================================================================
# Status
# =============================================================================

status: ## Show container and image status
	@echo "Container runtime: $(CONTAINER_RUNTIME)"
	@echo ""
	@echo "Claude credentials: $(CLAUDE_CREDENTIALS)"
	@if [ -f "$(CLAUDE_CREDENTIALS)" ]; then \
		echo "  Status: Found"; \
	else \
		echo "  Status: NOT FOUND (E2E tests will fail)"; \
	fi
	@echo ""
	@echo "Images:"
	@$(CONTAINER_RUNTIME) images $(IMAGE_NAME) 2>/dev/null || echo "  No image found"
	@echo ""
	@echo "Containers:"
	@$(CONTAINER_RUNTIME) ps -a --filter name=$(CONTAINER_NAME) 2>/dev/null || echo "  No containers"
