# Single command surface: `make install` and `make sast` (CI runs the same).
# Auto-detects the stack; edit a recipe to adapt it to your project.

.PHONY: help install sast

HAS_PY   := $(shell { [ -f pyproject.toml ] || ls requirements*.txt >/dev/null 2>&1 || git ls-files '*.py' 2>/dev/null | grep -q . ; } && echo yes)
HAS_JS   := $(shell [ -f package.json ] && echo yes)
HAS_GO   := $(shell [ -f go.mod ] && echo yes)
HAS_RUST := $(shell [ -f Cargo.toml ] && echo yes)
HAS_JAVA := $(shell { [ -f pom.xml ] || ls build.gradle* >/dev/null 2>&1 ; } && echo yes)

help:
	@echo "Targets: install | sast"
	@echo "Detected: Python=$(if $(HAS_PY),yes,no) Node=$(if $(HAS_JS),yes,no) Go=$(if $(HAS_GO),yes,no) Rust=$(if $(HAS_RUST),yes,no) Java=$(if $(HAS_JAVA),yes,no)"

install:
ifeq ($(HAS_PY),yes)
	python -m pip install --upgrade pip
	@[ -f requirements.txt ] && pip install -r requirements.txt || true
	@[ -f pyproject.toml ] && pip install -e ".[dev]" || pip install -e . || true
endif
ifeq ($(HAS_JS),yes)
	npm ci || npm install
endif
ifeq ($(HAS_GO),yes)
	go mod download
endif
ifeq ($(HAS_RUST),yes)
	@echo "rust: deps resolved on build"
endif
ifeq ($(HAS_JAVA),yes)
	@echo "java: deps resolved on build"
endif
	bash scripts/install-hooks.sh

sast:
	pip install semgrep >/dev/null 2>&1 || true
	semgrep --config=auto --error || true   # advisory; drop the trailing `|| true` to block
	@echo "sast: done"

