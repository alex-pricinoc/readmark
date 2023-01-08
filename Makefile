CURRENT_DIR=$(shell pwd)
LDFLAGS += -s -w

all: install

install: setup go_build

go_build: priv/go/readability

priv/go/readability: go_priv
	cd go_src/readability; go build -ldflags '$(LDFLAGS)' -o $(CURRENT_DIR)/$@

go_priv:
	mkdir -p priv/go

setup:
	mix setup

format f:
	mix format
	dprint fmt

start server:
	mix phx.server

check lint:
	mix deps.unlock --check-unused
	mix hex.audit
	mix compile --warnings-as-errors
	mix format --check-formatted
	dprint check
	mix credo --strict --only warning
	mix xref graph --label compile-connected --fail-above 0

check.format:
	mix format --check-formatted
	dprint check

check.deps:
	mix deps.unlock --check-unused
	mix hex.audit
	mix xref graph --label compile-connected --fail-above 0

check.outdated:
	mix hex.outdated

test:
	mix test

coverage:
	mix test --cover

clean:
	mix clean
	rm -rf priv/go

versions:
	@echo "Tool Versions"
	@cat .tool-versions
	@echo
