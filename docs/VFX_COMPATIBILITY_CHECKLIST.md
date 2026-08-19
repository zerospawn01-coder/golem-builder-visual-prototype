# VFX Compatibility Checklist

This checklist applies to every new visual effect, shader, particle system, material, and animated overlay in the visual prototype.

## V-TECH-01 baseline

- [ ] Effect renders with `gl_compatibility` on desktop.
- [ ] Effect renders with `gl_compatibility` on mobile.
- [ ] Effect does not require Forward+ features, clustered lighting, compute shaders, or renderer-specific storage buffers.
- [ ] Effect has no dependency on a Forward+ shader include or renderer-only built-in.
- [ ] Effect remains valid when the viewport is 1280×720.
- [ ] Effect remains valid when the viewport is 720×1280 portrait.
- [ ] Effect does not assume a fixed aspect ratio; crop and anchors are responsive.
- [ ] Effect does not change game results, telemetry, ACTION economy, damage, rewards, or Blueprint state.

## Shader review

- [ ] Shader language features are supported by Godot 4 Compatibility renderer.
- [ ] No `#include` or external dependency is required unless checked into this repository.
- [ ] Texture sampling has an explicit filter/repeat decision.
- [ ] Alpha, blend mode, and premultiplication behavior are documented.
- [ ] A missing or unsupported shader fails visibly and safely; it does not block the presentation state pipeline.

## Runtime review

- [ ] Desktop and portrait screenshots or framebuffer captures are recorded when a real renderer is available.
- [ ] The effect is disabled or replaced by a static fallback when the compatibility check cannot run.
- [ ] Headless dummy-renderer failures are recorded as `NOT EXECUTABLE`, never as an artificial PASS.
- [ ] The relevant regression test is added before the effect is treated as frozen.
