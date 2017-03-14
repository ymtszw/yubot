## Ref

- [Can I use webassembly ?](http://caniuse.com/#search=webassembly)
- [WebAssembly - MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly)
- [Binaryen](https://github.com/WebAssembly/binaryen)
- [WebAssemblyを使ってみる(C/C++をWebAssemblyに変換してChromeで実行)](http://qiita.com/Hiroki_M/items/89975a9e8205ced3603f)

---
## Prep

- llvm/clang
    - ターゲットアーキにWebAssemblyを含む`clang`と`llc`がインストールされる
    - 30分くらいかかる

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

---
- binaryen
  - `s2wasm`と`wasm-as`がインストールされる
- `sexpr-wasm-prototype`を入れないとバイナリをブラウザが読めない、という記事が散見されるが、
現時点では`wasm-as`が生成するバイナリで（少なくともChromeなら）動く

```sh
$ git clone https://github.com/WebAssembly/binaryen.git
$ cd binaryen
$ cmake . && make
$ sudo make install
```
---
## Build sequence

```
C source (.c)
-> LLVM-IR (.ll)
-> Assembly (.s)
-> WebAssembly text (.wast)
-> WebAssembly (.wasm)
```

---
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

---
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

---
## Build

```sh
$ cd src/
$ clang -S -emit-llvm -Oz --target=wasm32 fib.c
$ llc fib.ll -march=wasm32
$ s2wasm -s 100000 fib.s > fib.wast
$ wasm-as fib.wast > ../priv/static/fib.wasm
```

---
## Execution

`<script>`タグでソースを指定してembedするような便利な経路は現状ない。

1. XHRでバイナリファイル取得
2. バイナリを配列に変換し、`WebAssembly.instantiate()`で実行可能なInstanceに変換
3. Public関数がexportされるので、好きに使う

---
## With fetch

```js
fetch('/static/fib.wasm').then(response =>
  response.arrayBuffer()
).then(bytes =>
  WebAssembly.instantiate(bytes, {})
).then(result =>
  registerHandler('wasm', result.instance.exports.fib_to) // 別で定義
)
```

---
## Demo

https://yubot.solomondev.access-company.com/static/fib.html

- 指定されたフィボナッチ数を計算して`performance.now()`の差分で計測
- 50,000回の平均
- CベースWASMが大体10倍くらい速い
- まだwasm32（32bit-integer）であるため、単にやるとF_47でオーバーフローする

---
## Deploy

- 単にローカルでコンパイルしてバイナリをpriv/からサーブ
- wasmの容量は、今回のExample Codeだと最適化しても若干JSソースより大きい
    - JSは350B
    - Wasmは429B

---
## Future

- wasmまでのコンパイル経路が確立していて、ツールも揃っている言語は少ない
- [Rustでもできるようではある](http://qiita.com/_likr/items/daf46d6f66bc31cc4810)
    - `rustup`を使ってwasm32をターゲットアーキとして追加
    - `cargo`にオプションを付けてビルド、もしくは`rustc --emit=llvm-ir`して云々
- golangは[Tracking Issue](https://github.com/golang/go/issues/18892)だけ立っている

---
## Impression

- LLVM関連の環境インストールがむしろヘビー
- ひとたびコンパイル経路が確立すれば意外とすんなり動く
-

---
## Appendix

---
## LLVM-IR

```llvm
; ModuleID = 'fib.c'
source_filename = "fib.c"
target datalayout = "e-m:e-p:32:32-i64:64-n32:64-S128"
target triple = "wasm32"

; Function Attrs: minsize nounwind optsize readnone
define hidden i32 @fib(i32 %n1, i32 %n2, i32 %i, i32 %max) local_unnamed_addr #0 {
entry:
  br label %tailrecurse

tailrecurse:                                      ; preds = %if.end, %entry
  %n1.tr = phi i32 [ %n1, %entry ], [ %n2.tr, %if.end ]
  %n2.tr = phi i32 [ %n2, %entry ], [ %add, %if.end ]
  %i.tr = phi i32 [ %i, %entry ], [ %add1, %if.end ]
  %cmp = icmp eq i32 %i.tr, %max
  br i1 %cmp, label %return, label %if.end

if.end:                                           ; preds = %tailrecurse
  %add = add nsw i32 %n2.tr, %n1.tr
  %add1 = add nsw i32 %i.tr, 1
  br label %tailrecurse

return:                                           ; preds = %tailrecurse
  ret i32 %n1.tr
}

; Function Attrs: minsize norecurse nounwind optsize readnone
define hidden i32 @fib_to(i32 %max) local_unnamed_addr #1 {
entry:
  br label %tailrecurse.i

tailrecurse.i:                                    ; preds = %if.end.i, %entry
  %n1.tr.i = phi i32 [ 0, %entry ], [ %n2.tr.i, %if.end.i ]
  %n2.tr.i = phi i32 [ 1, %entry ], [ %add.i, %if.end.i ]
  %i.tr.i = phi i32 [ 0, %entry ], [ %add1.i, %if.end.i ]
  %cmp.i = icmp eq i32 %i.tr.i, %max
  br i1 %cmp.i, label %fib.exit, label %if.end.i

if.end.i:                                         ; preds = %tailrecurse.i
  %add.i = add nsw i32 %n2.tr.i, %n1.tr.i
  %add1.i = add nuw nsw i32 %i.tr.i, 1
  br label %tailrecurse.i

fib.exit:                                         ; preds = %tailrecurse.i
  ret i32 %n1.tr.i
}

attributes #0 = { minsize nounwind optsize readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { minsize norecurse nounwind optsize readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 5.0.0 (http://llvm.org/git/clang.git e3a2454ea8263759d2ac667d3e086bb15269e10e) (http://llvm.org/git/llvm.git cd2a5b62d109d6864f2c566efab8e1dfb93f0550)"}
```

---
## Assembly

```s
.text
.file	"fib.ll"
.hidden	fib
.globl	fib
.type	fib,@function
fib:                                    # @fib
.param  	i32, i32, i32, i32
.result 	i32
# BB#0:                                 # %entry
i32.sub 	$3=, $3, $2
.LBB0_1:                                # %tailrecurse
                                      # =>This Inner Loop Header: Depth=1
block
loop    	                # label1:
i32.eqz 	$push1=, $3
br_if   	1, $pop1        # 1: down to label0
# BB#2:                                 # %if.end
                                      #   in Loop: Header=BB0_1 Depth=1
i32.const	$push0=, -1
i32.add 	$3=, $3, $pop0
i32.add 	$2=, $1, $0
copy_local	$0=, $1
copy_local	$1=, $2
br      	0               # 0: up to label1
.LBB0_3:                                # %return
end_loop
end_block                       # label0:
copy_local	$push2=, $0
                                      # fallthrough-return: $pop2
.endfunc
.Lfunc_end0:
.size	fib, .Lfunc_end0-fib

.hidden	fib_to
.globl	fib_to
.type	fib_to,@function
fib_to:                                 # @fib_to
.param  	i32
.result 	i32
.local  	i32, i32, i32
# BB#0:                                 # %entry
i32.const	$3=, 1
i32.const	$2=, 0
.LBB1_1:                                # %tailrecurse.i
                                      # =>This Inner Loop Header: Depth=1
block
loop    	                # label3:
i32.eqz 	$push1=, $0
br_if   	1, $pop1        # 1: down to label2
# BB#2:                                 # %if.end.i
                                      #   in Loop: Header=BB1_1 Depth=1
i32.const	$push0=, -1
i32.add 	$0=, $0, $pop0
i32.add 	$1=, $3, $2
copy_local	$2=, $3
copy_local	$3=, $1
br      	0               # 0: up to label3
.LBB1_3:                                # %fib.exit
end_loop
end_block                       # label2:
copy_local	$push2=, $2
                                      # fallthrough-return: $pop2
.endfunc
.Lfunc_end1:
.size	fib_to, .Lfunc_end1-fib_to


.ident	"clang version 5.0.0 (http://llvm.org/git/clang.git e3a2454ea8263759d2ac667d3e086bb15269e10e) (http://llvm.org/git/llvm.git cd2a5b62d109d6864f2c566efab8e1dfb93f0550)"
```

---
## WASM-Text

```wast
(module
 (table 0 anyfunc)
 (memory $0 2)
 (data (i32.const 4) "\b0\86\01\00")
 (export "memory" (memory $0))
 (export "fib" (func $fib))
 (export "fib_to" (func $fib_to))
 (func $fib (param $0 i32) (param $1 i32) (param $2 i32) (param $3 i32) (result i32)
  (set_local $3
   (i32.sub
    (get_local $3)
    (get_local $2)
   )
  )
  (block $label$0
   (loop $label$1
    (br_if $label$0
     (i32.eqz
      (get_local $3)
     )
    )
    (set_local $3
     (i32.add
      (get_local $3)
      (i32.const -1)
     )
    )
    (set_local $2
     (i32.add
      (get_local $1)
      (get_local $0)
     )
    )
    (set_local $0
     (get_local $1)
    )
    (set_local $1
     (get_local $2)
    )
    (br $label$1)
   )
  )
  (get_local $0)
 )
 (func $fib_to (param $0 i32) (result i32)
  (local $1 i32)
  (local $2 i32)
  (local $3 i32)
  (set_local $3
   (i32.const 1)
  )
  (set_local $2
   (i32.const 0)
  )
  (block $label$0
   (loop $label$1
    (br_if $label$0
     (i32.eqz
      (get_local $0)
     )
    )
    (set_local $0
     (i32.add
      (get_local $0)
      (i32.const -1)
     )
    )
    (set_local $1
     (i32.add
      (get_local $3)
      (get_local $2)
     )
    )
    (set_local $2
     (get_local $3)
    )
    (set_local $3
     (get_local $1)
    )
    (br $label$1)
   )
  )
  (get_local $2)
 )
)
```
