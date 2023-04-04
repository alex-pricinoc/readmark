MIX_APP_PATH=$(shell pwd)
LDFLAGS += -s -w

all: install

install: setup go_build

setup:
	mix setup

go_build: priv/go/readability

priv/go/readability: go_priv
	cd go_src/readability; go build -ldflags '$(LDFLAGS)' -o $(MIX_APP_PATH)/$@

go_priv:
	mkdir -p priv/go


start server:
	mix phx.server

format f:
	mix format
	dprint fmt

precommit: check test native


check lint:
	mix lint
	dprint check
	mix hex.audit
	mix deps.audit

check.deps.outdated:
	mix hex.outdated


test:
	mix test

test.coverage:
	mix coveralls

test.coverage.html:
	mix coveralls.html


native:
	make --directory native/epub


clean:
	mix clean
	rm -rf priv/go
	rm -rf priv/native
	make clean --directory native/epub

clean.deps.unused:
	mix deps.clean --unlock --unused

.PHONY: test native
