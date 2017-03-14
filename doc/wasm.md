# Wasm

## Ref

- [Can I use webassembly ?](http://caniuse.com/#search=webassembly)
- [WebAssembly - MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly)
- [Binaryen](https://github.com/WebAssembly/binaryen)
- [WebAssemblyを使ってみる(C/C++をWebAssemblyに変換してChromeで実行)](http://qiita.com/Hiroki_M/items/89975a9e8205ced3603f)

## Prep

- llvm/clang
  ```sh
  $ WORKDIR=$(pwd)
  $ git clone http://llvm.org/git/llvm.git
  $ git clone http://llvm.org/git/clang.git llvm/tools/clang
  $ git clone http://llvm.org/git/compiler-rt llvm/projects/compiler-rt
  $ mkdir llvm_build
  $ cd llvm_build/
  $ cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr/local -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly "$WORKDIR/llvm"
  $ make -j 8
  $ sudo make install
  ```
    - `clang`と`llc`がインストールされる
- binaryen
  ```sh
  $ git clone https://github.com/WebAssembly/binaryen.git
  $ cd binaryen
  $ cmake . && make
  $ sudo make install
  ```
    - `s2wasm`と`wasm-as`がインストールされる

## Build sequence

```
C source (.c)
-> LLVM-IR (.ll)
-> Assembly (.s)
-> WebAssembly text (.wast)
-> WebAssembly (.wasm)
```

## Example code in C

```c
int fib(n1, n2, i, max) {
  if (i == max) return n1;
  return fib(n2, n1 + n2, i + 1, max);
}

int fib_to(max) {
  return fib(0, 1, 0, max);
}
```

## Example code in JavaScript

```js
function fib(n1, n2, i, max) {
  if (i == max) return n1;
  return fib(n2, n1 + n2, i + 1, max);
}

function fib_to(max) {
  return fib(0, 1, 0, max);
}
```

## Build

```sh
$ cd src/
$ clang -S -emit-llvm -Oz --target=wasm32 fib.c
$ llc main.ll -march=wasm32
$ s2wasm -s 100000 main.s > main.wast
$ wasm-as main.wast >
```

## Execution

`<script>`タグでソースを指定してembedするような便利な経路は現状ない。

1. XHRでバイナリファイル取得
2. バイナリを配列に変換し、`WebAssembly.instantiate()`で実行可能なInstanceに変換
