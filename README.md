# GOLEM BUILDER EXPEDITION — Visual Prototype

> **STATUS:** VISUAL PROTOTYPE  
> **CANONICAL:** NO  
> **RULE AUTHORITY:** `golem-builder-expedition`

PC・モバイル向けの遠征監視画面を検証する、Godot 4製Presentation Layerです。ゲームルールやバランスを計算せず、受信したTelemetryをUI・ログ・警告・仮アニメーションとして表現します。

> ゲーム本体が結果を決定し、Visual Prototypeがその結果を画面上で演じる。

## Current vertical slice

起動すると5件のMock Telemetryを順番に再生します。

```text
IDLE → WALKING → HARVESTING → HAZARD → DECISION
```

- `sequence` による古い更新の拒否
- `status`（現在状態）と `log_events`（発生イベント）の分離
- DEPTH / DURABILITY / CARGO表示
- Diagnostic Logへのイベント追記
- HAZARD警告
- CONTINUE / RETURN表示（表示専用）
- 仮矩形によるGolemView状態表現
- PC / Mobileレイアウトの画面幅による切り替え

Godot 4で `project.godot` を開いて実行してください。

## Boundaries

このリポジトリでは、損傷計算、ACTION economy、成功条件、パーツ性能、Blueprintロジック、修理経済、進行条件、報酬バランスを実装しません。

