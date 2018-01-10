Yubot
=========

Playground for me.

# WASM

WebAssemblyを使ってみた的な内容。勉強会で発表したネタ。

詳細は[doc/wasm.md](./doc/wasm.md)参照。

# Poller

WebUIから任意のAPIに対するPolling Botを作成できるアプリ。

[Elm][elm]によるアプリ開発の試行として2017年前半に個人開発。

[elm]: http://elm-lang.org

元々`elm-make`を直接使うビルドフロー＋自前のCDN機構を使っていたが、
solomon公式でnpm-scriptsからのビルド及びCDN機能が導入されたので2018年1月にそちらに移行。
