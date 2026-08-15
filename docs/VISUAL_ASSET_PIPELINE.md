# Visual Asset Pipeline v1

```text
assets/source → exported PNG → assets/runtime → Godot import → Texture2D → View
```

`assets/source/.gdignore`は制作元データをGodotのFileSystem、import、exportから隔離します。変換ツールは`tools/assets/`からruntime assetを生成します。

## Runtime raster baseline

| Property | Baseline |
|---|---|
| Format | PNG |
| Opaque background | RGB |
| Transparency | RGBA |
| Import type | Texture2D |
| Compression | Lossless |
| Mipmaps | Off |
| Filter | CanvasItem Linear |
| Repeat | Enabled only on scrolling layers |
| Maximum environment texture | 2048×1024 |
| 4096 texture | Prohibited without measured exception |

PCとMobileは同じruntime textureを使用し、View側のcover、crop、anchor、layer offsetで表示を変えます。端末別画像は初期規格に含めません。

## Version control and loading

- `assets/runtime/**/*.png`と隣接する`*.png.import`をコミットする。
- 再生成可能な`.godot/` cacheはコミットしない。
- import済みruntime assetはscene参照、`load()`、`preload()`などResourceLoader経由で取得する。
- import済み画像を`FileAccess`で直接ロードしない。export後の内部配置は`.godot/imported/`へ変わるためである。
- Git LFSはfixture段階では使用せず、実素材導入時に容量基準とともに判断する。

RGBA8 mipmapなしの概算GPUメモリは `width × height × 4 bytes`、RGB8は`width × height × 3 bytes`として予算化します。実測が可能になった段階でGodot Inspectorおよび対象端末のプロファイル結果を優先します。
