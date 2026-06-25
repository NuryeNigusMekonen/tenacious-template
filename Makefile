# The single command surface for this project.
# CI calls `make sast`, so local and pipeline behaviour stay identical.
# (Secret scanning runs via scripts/secret-scan.sh directly - hooks + CI.)
#
# Auto-detects Python and/or Node and runs the right commands. A polyglot repo
# (both) runs both. Override any command by editing the recipe for your stack.

.PHONY: help install sast

# --- stack detection ---------------------------------------------------------
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
	@# Project deps only; `make sast` installs Semgrep on demand.
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
	@# cargo fetches deps on first build/test; nothing to pre-install.
	@echo "rust: deps resolved on build"
endif
ifeq ($(HAS_JAVA),yes)
	@# Maven/Gradle resolve deps on first build; nothing to pre-install.
	@echo "java: deps resolved on build"
endif
	@# Activate the secret-scanning hooks on every setup.
	bash scripts/install-hooks.sh

sast:
	@# Semgrep is the single SAST tool - multi-language (covers Python, JS/TS,
	@# Go, etc.) and runs for any stack on every PR/push. CI calls this target.
	pip install semgrep >/dev/null 2>&1 || true
	semgrep --config=auto --error || true   # advisory; flip --error to block
	@echo "sast: done"

