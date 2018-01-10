MAKEFLAGS += --no-print-directory
SHELL = bash

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
	@YUBOT_CONFIG_JSON='$(shell cat ./gear_config)' LOG_LEVEL=debug iex -S mix
gear_config:
	echo "gear_config file is missing"
	exit 1

.PHONY: test_blackbox_local
test_blackbox_local: gear_config started
	@BLACKBOX_TEST_SECRET_JSON='$(shell cat ./gear_config)' TEST_MODE=blackbox_local mix test
started:
	curl -fso /dev/null http://yubot.localhost:8080/
