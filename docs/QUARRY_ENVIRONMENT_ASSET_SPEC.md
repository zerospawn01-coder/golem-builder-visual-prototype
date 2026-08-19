# Quarry Environment Asset Specification v1

## Status and scope

```text
PHASE       V5 — First Real Environment Asset
TARGET      Quarry / 採石区域
STATUS      SPECIFICATION FROZEN
CANONICAL   Visual presentation only
```

この仕様は最初の実背景1セットをV4 Asset Pipelineへ投入するための制作契約です。ゲーム上の危険度、移動速度、採取量、成功条件は定義しません。ゴーレム、UI、Particle、Shader、動画、端末別画像は対象外です。

## Specification and deliverable lifecycle

```text
SPECIFICATION
Status              FROZEN

TECHNICAL REFERENCE
Quarry V1           Technical baseline / evidence
Status              PRESERVED

ART REVISION
Quarry V2           North Star alignment source
Status              READY FOR PRODUCTION

DELIVERABLE
Status              FROZEN
```

`V5 SPECIFICATION FROZEN`は制作契約が固定されたことを示し、`V5 DELIVERABLE FROZEN`はその契約を満たした実素材がruntime framebufferと全Gateを通過したことを示します。この2状態を同一視しません。

Runtime suffix `_v1` denotes the V5 runtime contract version, not the source-art revision number. Quarry V2以降のsourceを承認・exportしても、V5契約内ではruntime filenameの`_v1`を変更しません。

## Deliverables

| Layer | Runtime filename | Channels | Ownership |
|---|---|---|---|
| Background | `quarry_background_v1.png` | RGB | 遠景の岩壁、空間の大きな明暗、遠距離地形 |
| Midground | `quarry_midground_v1.png` | RGBA | 岩柱、採掘設備、中距離の輪郭 |
| Foreground | `quarry_foreground_v1.png` | RGBA | 足場、瓦礫、近景岩、接地感 |

Runtime配置先：

```text
assets/runtime/environment/quarry/
├─ background/quarry_background_v1.png
├─ midground/quarry_midground_v1.png
└─ foreground/quarry_foreground_v1.png
```

Sourceとruntimeの責務は次で固定します。すべてのsourceは`.gdignore`境界内に置きます。

```text
assets/source/environment/quarry/
├─ reference/quarry_v1/
│  ├─ quarry_background_v1_source.png
│  ├─ quarry_midground_v1_source.png
│  └─ quarry_foreground_v1_source.png
├─ quarry_background_v2_source.*
├─ quarry_midground_v2_source.*
└─ quarry_foreground_v2_source.*

approved export
        ↓

assets/runtime/environment/quarry/
├─ background/quarry_background_v1.png
├─ midground/quarry_midground_v1.png
└─ foreground/quarry_foreground_v1.png
```

Quarry V1 sourceと検査画像はtechnical referenceとして保存し、North Star alignmentの品質基準にはしません。Quarry V2 sourceは承認前にruntimeへ直接参照させません。

## Canvas and resolution policy

```text
Preferred production size   1024 × 512
Hard maximum                2048 × 1024
Aspect ratio                2:1
4K                          Prohibited
Device variants             None
Runtime format              PNG
```

3レイヤーは同一寸法・同一原点を使用します。最大寸法は品質目標ではなく例外上限です。1024×512で検証し、実機計測で不足を証明できた場合のみ2048×1024を検討します。

## Safe crop policy

同一2:1 textureをaspect-preserving `cover`で表示し、中央anchorを基準にcropします。Reference viewportはPC 16:9とMobile 9:16です。

```text
Normalized safe region
X   0.36 .. 0.64
Y   0.12 .. 0.88

1024 × 512 coordinates
X   369 .. 655
Y    61 .. 451
```

- Safe region内にもゲーム判断に必要な情報を焼き込まない。
- 採石区域を識別する主要な形・明暗焦点はSafe regionから完全に失われないようにする。
- 左右のcrop expendable領域へ、切断されると不自然な単独ランドマークを置かない。
- UI文字、警告記号、ルート情報、採取結果を背景へ描かない。
- 水平スクロールにより任意の位相が表示されるため、唯一性のある重要物を前提にしない。

### Crop render contract

```text
Mode        CENTER-COVER
Anchor      X = 0.50 / Y = 0.50
Scaling     Uniform only; non-uniform stretch prohibited
Resources   Same Texture2D on PC and Mobile
```

Texture寸法を`Tw × Th`、表示領域を`Vw × Vh`とすると、scaleと中央crop原点は次で決定します。

```text
scale   = max(Vw / Tw, Vh / Th)
crop_x  = (Tw * scale - Vw) / 2
crop_y  = (Th * scale - Vh) / 2
```

- textureを縦横同一scaleでView全体が埋まるまで拡大・縮小し、View外へ出た部分だけをclipする。
- scroll offsetは反復layerの表示座標へ適用し、その後View境界でclipする。scrollのためにtextureを非均一変形しない。
- scroll位相0では中央anchorがtexture中央と一致する。scroll中は反復textureの任意位相が現れるため、Safe regionは構図基準であり、ゲーム情報の可視性保証には使用しない。
- resize時はcover geometryだけを再計算し、PresentationState、EnvironmentController、scroll phaseを再生成・リセットしない。

1024×512 sourceに対するreference Gateは次のとおりです。

```text
PC 16:9
→ aspect ratio preserved
→ center anchor preserved at scroll phase 0
→ no geometric stretching

Mobile 9:16
→ aspect ratio preserved
→ source X 36% .. 64% is the minimum centered visible band
→ source Y 12% .. 88% remains inside the visible height
→ no geometric stretching
```

## Horizontal seam contract

- 全レイヤーはX方向に無限反復可能であること。
- 左端と右端の境界で、各scanlineの色、alpha、輪郭、明度、地面高、alpha勾配が視覚的に連続すること。
- 端で切れる形状は反対端へ連続させること。
- Generatorや編集ツール上で`A | A`を反復合成し、境界左右各8pxのwrap seam compositeを100%表示で検査すること。
- compositeにcolor／alpha discontinuityや明白なedge duplicationがないこと。左右8pxの単純な完全コピーだけを合格条件にしない。
- EnvironmentControllerの速度比 `0.25 / 0.55 / 1.00` は変更しない。

## Alpha contract

```text
Background   Opaque RGB; alpha channelなし
Midground   Straight alpha RGBA
Foreground  Straight alpha RGBA
Premultiplied alpha   No
Fix alpha border      Yes
```

- Midground／Foregroundには透明pixelを必ず含める。
- 半透明edgeのRGBは隣接する可視色から自然に延長し、白・黒のmatteを残さない。
- Godotの`process/fix_alpha_border=true`を維持する。
- Layer全体の不透明な矩形背景はBackgroundだけが所有する。

## Layer composition rules

### Background

- 画面全体を不透明に覆う。
- 小さな高周波detailを避け、最も遅いscrollで遠景として読める構成にする。
- Golem silhouetteの背後に十分な明度差を確保する。

### Midground

- 透明領域を通してBackgroundを見せる。
- Golemの全身を恒常的に覆う大面積の不透明形状を避ける。
- 採掘設備は世界表現であり、操作可能UIのような記号表現を避ける。

### Foreground

- 画面下部の接地感を主に担当する。
- Golemの脚部を部分的に横切ることは許可するが、本体中心を長時間隠さない。
- 最速scrollでもちらつかない大きさの形状を使う。

## Import and CanvasItem settings

```text
Import type      Texture2D / CompressedTexture2D
Compression      Lossless (`compress/mode=0`)
Mipmaps          Off (`mipmaps/generate=false`)
Filter           CanvasItem Linear
Repeat           CanvasItem Enabled
Fix alpha border On
```

runtime PNGと隣接する`.png.import`をVCSへ含めます。`.godot/` cacheは含めません。Scene、`load()`、`preload()`などResourceLoader経路だけで参照し、import済み画像をProductionコードから`FileAccess`で直接読みません。

## Resource budgets

### GPU memory estimate, mipmaps off

| Size | Background RGB | Midground RGBA | Foreground RGBA | Set total |
|---|---:|---:|---:|---:|
| 1024×512 | 1.50 MiB | 2.00 MiB | 2.00 MiB | 5.50 MiB |
| 2048×1024 | 6.00 MiB | 8.00 MiB | 8.00 MiB | 22.00 MiB |

```text
Preferred set ceiling   6 MiB estimated GPU memory
Hard set ceiling       24 MiB estimated GPU memory
Preferred PNG disk     8 MiB total or less
Single PNG disk        3 MiB or less
```

Hard ceilingは使用目標ではありません。超過時は解像度、alpha有無、detail密度を見直し、例外として記録します。

## Responsive behavior

- PC／Mobileで同一Texture2Dを共有する。
- 中央anchorのaspect-preserving coverを使用する。
- Viewport変更はcropだけを更新し、PresentationState、EnvironmentController、scroll phaseを再生成しない。
- MobileでSafe regionとGolem silhouetteが同時に読めること。
- 端末別textureや端末別Environment Stateを作らない。

## Performance target

```text
PC       60 FPS
Android  WAIVED — actual device unavailable; not a PASS
```

V5ではGodot profilerまたは同等のframe measurementを記録します。画像導入前後を同条件で比較し、EnvironmentControllerの更新量やTelemetry頻度を変更して数値を合わせません。

## V5 gate

```text
V5-QUARRY-ASSET

SPECIFICATION
[ ] filenames / dimensions / channels conform
[ ] source and runtime remain separated
[ ] no device variants or 4K assets

IMPORT
[ ] PNG → Texture2D
[ ] Lossless / mipmaps off
[ ] .png.import tracked
[ ] alpha and fix-alpha-border conform

COMPOSITION
[ ] horizontal seam and 8px band pass
[ ] layer ownership pass
[ ] depth dimming remains readable
[ ] hazard overlay remains readable

RESPONSIVE
[ ] CENTER-COVER formula and center anchor pass
[ ] PC 16:9 preserves aspect ratio and center anchor at phase 0
[ ] Mobile 9:16 preserves X 36%..64% and Y 12%..88%
[ ] no non-uniform geometric stretching
[ ] same Texture2D resources on both layouts
[ ] resize does not reset state or scroll phase

RESOURCE / PERFORMANCE
[ ] dimensions and PNG file sizes recorded
[ ] estimated texture memory within budget
[ ] PC 60 FPS pass
[x] Android actual-device Gate explicitly WAIVED; no device available; not recorded as PASS

ARCHITECTURE
[ ] EnvironmentController unchanged
[ ] Golem remains placeholder
[ ] V0–V4 all pass
[ ] debugger errors/warnings none
```

## V5 composite gate

Composite Gateはsource単体ではなく、Godot import、CENTER-COVER、parallax、depth modulation、hazard overlay、Golem placeholder、PC／Mobile UIを合成したruntime framebufferを評価します。

### Measurement placeholder contract

Measurement placeholderはアート資産でも将来のGolem silhouette仕様でもなく、背景とUIを測るための固定測定器です。特定のplaceholder輪郭に背景を過適合させません。

```text
POSE
NEUTRAL
WALKING_EXTENT
HAZARD_REACTION_EXTENT

SIGNAL
NO_LIGHT
NORMAL_CYAN
WARNING_AMBER
CRITICAL_RED
```

3 pose × 4 signalの全12状態を、PC 1280×720とMobile 720×1280の実Godot framebufferで取得します。評価対象は輪郭分離、局所コントラスト、UI可読性、焦点階層です。背景の合格条件は特定輪郭との一致ではなく、中央Safe Regionの低情報密度とsignal colorの分離です。

```text
tests/visual_log/v5_composite_baseline/
├─ quarry_pc_measurement_baseline.png
└─ quarry_mobile_measurement_baseline.png
```

Baseline captureの生成成功はComposite Gateの測定可能性だけを示し、North Star alignment PASSやV5 Deliverable Frozenを意味しません。

```text
V5-COMPOSITE-GATE

A. SUBJECT PRIORITY
[ ] Golem silhouette readable
[ ] central safe region remains low-density
[ ] background detail does not dominate subject
[ ] WALKING / HAZARD reaction remain readable

B. COLOR LANGUAGE
[ ] normal cyan readable
[ ] warning amber/orange readable
[ ] critical orange-red/red strongest
[ ] environment cyan remains lower-saturation/lower-emphasis
[ ] environment does not use competing warning reds

C. PC COMPOSITION
[ ] environment remains primary viewport
[ ] right-side log/map/status remain readable
[ ] UI blocks do not obscure critical subject area
[ ] retreat action preserves highest hierarchy

D. MOBILE COMPOSITION
[ ] CENTER-COVER keeps Golem placement viable
[ ] environment + log upper composition remains readable
[ ] vertical status stack remains legible
[ ] bottom decision area remains visually dominant
```

## Acceptance order

```text
1. Composite Gate definition
2. Golem placeholder composite
3. PC UI block composite
4. Mobile UI block composite
5. Quarry V2 source production
6. Export to frozen runtime filenames
7. Runtime framebuffer Gate
8. North Star alignment review
9. V0–V4 regression
10. V5 DELIVERABLE FROZEN
```

North Star alignmentはsource画像だけでは判定せず、actual Godot import、actual crop、actual parallax、actual depth modulation、actual hazard overlay、actual UI placementを通したruntime framebufferの後に判定します。

## Final V5 disposition

```text
ART / COMPOSITE           PASS
RUNTIME CONFORMANCE       PASS
PC PERFORMANCE            PASS
ANDROID ACTUAL DEVICE     WAIVED — DEVICE UNAVAILABLE

V5 DELIVERABLE            FROZEN
V5 VERDICT                PASS
```

Android actual-device validation succeededとはみなしません。利用可能な実機がないためV5の受入条件から明示的に除外した記録です。将来Android対応を再開する場合は、V5を再オープンせず独立したdevice-validation Gateで管理します。
