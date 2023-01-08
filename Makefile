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

