#!/usr/bin/env bash
pushd src/
clang -S -emit-llvm -Oz --target=wasm32 fib.c
llc fib.ll -march=wasm32
s2wasm -s 100000 fib.s > fib.wast
wasm-as fib.wast > ../priv/static/fib.wasm
popd
