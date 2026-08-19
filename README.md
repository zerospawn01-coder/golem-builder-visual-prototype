# GOLEM BUILDER EXPEDITION — Visual Prototype

> **STATUS:** VISUAL PROTOTYPE  
> **CANONICAL:** NO  
> **RULE AUTHORITY:** `golem-builder-expedition`

PC・モバイル向けの遠征監視画面を検証する、Godot 4製Presentation Layerです。ゲームルールやバランスを計算せず、受信したTelemetryをUI・ログ・警告・仮アニメーションとして表現します。

> ゲーム本体が結果を決定し、Visual Prototypeがその結果を画面上で演じる。

## Technical Baseline

`GODOT_BINARY = C:\\Users\\zeros\\OneDrive\\Desktop\\Godot_v4.7.1-stable_win64.exe` (Godot 4.7.1 stable; fixed verification binary)

`V-TECH-01` freezes the runtime target for the visual prototype before dynamic golem work begins.

```text
Renderer       gl_compatibility (desktop + mobile)
PC reference   1280×720 / VSync OFF
Mobile target  9:16 portrait (720×1280 reference viewport)
```

- [x] Compatibility renderer is explicit in `project.godot`.
- [x] PC reference viewport is 1280×720 and VSync is explicitly disabled.
- [x] No Forward+ renderer dependency, Forward+ shader, or VFX shader is present in the repository.
- [x] Windows PC launch confirmation — Godot 4.7.1 stable GUI run verified at the 1280×720 project viewport; VSync OFF is fixed in `project.godot`.
- [ ] Mobile portrait launch confirmation — manual device/emulator check required.
- [x] VFX compatibility checklist is frozen in [`docs/VFX_COMPATIBILITY_CHECKLIST.md`](docs/VFX_COMPATIBILITY_CHECKLIST.md).

The two unchecked launch items are evidence gates, not renderer configuration defaults. They must be completed on a Windows PC and a 9:16 portrait device/emulator before `V-TECH-01` is promoted from implementation-ready to hardware-verified.

## Current vertical slice

`NORTH_STAR_INTEGRATION_V0` connects the presentation-only cycle:

```text
WORKSHOP → DESIGN / BLUEPRINT → FABRICATION CONFIRMED
         → EXPEDITION → HAZARD / RESULT → RETURN → WORKSHOP
```

Workshop, Blueprint, fabrication, and result screens consume immutable host snapshots. They do not save canonical Blueprints, calculate fabrication, spend ACTION, determine damage, or award cargo. The embedded Expedition view retains its existing telemetry pipeline.

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

## Presentation pipeline

```text
ExpeditionTelemetry
        ↓
ExpeditionPresenter
        ├─ PresentationState ──→ persistent view state
        └─ TransientEventBatch → one-shot feedback / diagnostic events
```

Viewは`ExpeditionTelemetry`を直接参照しません。`PresentationState`は受信値を表示用に写像するだけで、損傷、成功条件、報酬などのゲーム結果を計算しません。
Presenterは最新のPersistent Stateを保持し、View再生成時にはTelemetryを再処理せず再バインドできます。この操作でTransient Eventは再発火しません。StateとEvent BatchはネストしたDictionary／Arrayを含めてread-only化され、consumerからPresenter保持状態を変更できません。

## Motion prototype

`MotionController`がPersistent Stateを`AnimationPlayer`のループへ、Transient Eventをone-shot reactionへ写像します。仮図形の`GolemView`はstatusを解釈せず、AnimationPlayerから受け取るoffset、rotation、leg phase、reaction strengthだけを描画します。one-shot終了後は保持中のpersistent motionへ復帰します。

## Environment prototype

`EnvironmentController`はPresentationStateから表示用の`depth / hazards / activity`を決定します。`EnvironmentView`は仮矩形のbackground／midground／foregroundを固定速度比でスクロールし、depthによる視覚強度とhazard overlayを描画します。Telemetry、GolemView、ゲーム進行速度には依存しません。

## Visual asset pipeline

元データは`assets/source/`、Godot投入PNGは`assets/runtime/`へ分離します。V4では256×128の決定的なテストパターンをTexture2Dとして読み込み、Lossless、mipmapなし、CanvasItem Linear filter／RepeatでV3の3レイヤーへbindingします。規格は[Visual Asset Pipeline](docs/VISUAL_ASSET_PIPELINE.md)を参照してください。

最初の実背景Quarryの寸法、safe crop、seam、alpha、レイヤー責務、Composite Gate、メモリ・ファイル容量予算は[Quarry Environment Asset Specification](docs/QUARRY_ENVIRONMENT_ASSET_SPEC.md)で管理します。V5 SpecificationとV5 DeliverableはFrozenです。Android実機Gateは端末を利用できないためPASSではなくWAIVEDとして記録しています。

Godot 4で `project.godot` を開いて実行してください。

## Boundaries

このリポジトリでは、損傷計算、ACTION economy、成功条件、パーツ性能、Blueprintロジック、修理経済、進行条件、報酬バランスを実装しません。
