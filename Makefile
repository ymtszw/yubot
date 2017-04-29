MAKEFLAGS += --no-print-directory
SHELL = bash

.PHONY: all
all: ui ;

.PHONY: wasm
wasm: wasm/_build/fib.wast
	wasm-as wasm/_build/fib.wast > priv/static/fib.wasm
wasm/_build/fib.wast: wasm/_build/fib.s
	s2wasm -s 100000 wasm/_build/fib.s > wasm/_build/fib.wast
wasm/_build/fib.s: wasm/_build/fib.ll
	llc wasm/_build/fib.ll -march=wasm32
wasm/_build/fib.ll: wasm/_build wasm/src/fib.c
	clang -S -emit-llvm -Oz --target=wasm32 -o wasm/_build/fib.ll wasm/src/fib.c
wasm/_build:
	mkdir -p wasm/_build

.PHONY: start
start: gear_config
	@YUBOT_CONFIG_JSON='$(shell cat ./gear_config)' iex -S mix
gear_config:
	@echo "gear_config file is missing"
	@exit 1

.PHONY: test_blackbox_local
test_blackbox_local: gear_config started
	@BLACKBOX_TEST_SECRET_JSON='$(shell cat ./gear_config)' TEST_MODE=blackbox_local TEST_PORT=8080 PORT=8081 mix test
started:
	@curl -fso /dev/null http://yubot.localhost:8080/

.PHONY: ui
ui: poller ;

.PHONY: poller
poller:
	elm-make --debug --warn --output=priv/static/poller.js ui/src/Poller.elm

.PHONY: uiwatch
uiwatch:
	make ui
	fswatch -o -l 2 ui/src elm-package.json | xargs -n1 -x -I{} make ui
