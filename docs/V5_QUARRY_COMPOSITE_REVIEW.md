# V5 Quarry Composite Review

## Review boundary

This review compares the preserved Quarry V1 technical baseline with the staged Quarry V2 candidate under the same 3-pose × 4-signal measurement matrix. A capture PASS only proves that the harness rendered; the verdict below records the visual Composite Gate review.

```text
V1 ROLE             Technical baseline / evidence
V2 ROLE             North Star alignment candidate
RUNTIME EXPORT      Authorized only after this review passes
```

## V2 candidate verdict

```text
Pale leg separation                 PASS
WALKING / HAZARD extent clearance   PASS
Cyan signal separation              PASS
PC right UI separation              PASS
Mobile section separation           PASS
Dark foreground leg readability     PASS
9:16 low-density center band         PASS

VERDICT                              COMPOSITE PASS
```

Compared with Quarry V1, V2 lowers central background luminance and saturation, preserves a quieter central band, and keeps the placeholder's pale extremities readable. Environment cyan remains darker and less saturated than the normal cyan signal. Warning amber and critical red retain stronger focal priority. PC and Mobile UI blocks remain spatially separated from the environment viewport.

## Evidence

```text
tests/visual_log/v5_composite_baseline/
tests/visual_log/v5_composite_v2_candidate/
```

## Runtime verification

```text
V2 source → frozen runtime export     PASS
Candidate/runtime PNG SHA-256         EXACT MATCH (3/3 layers)
Godot import                          PASS
PC candidate/runtime framebuffer      EXACT MATCH
Mobile candidate/runtime framebuffer  EXACT MATCH
V0–V5 regression                      PASS

PC FPS measurement                    PASS
Android actual device                 WAIVED — DEVICE UNAVAILABLE (not PASS)
V5 DELIVERABLE                        FROZEN
V5 VERDICT                            PASS
```

PC evidence was measured at 1280×720 with the AMD Radeon OpenGL 3.3 Compatibility renderer, VSync forced off, one second of warmup, and five seconds per state. TRAVERSAL averaged 875.1 FPS and repeated HAZARD reaction averaged 758.3 FPS; both exceed the frozen 60 FPS target. The machine-readable record is `tests/visual_log/v5_performance/pc_performance.json`.

The Composite Gate, runtime conformance, and PC Performance Gate are established. Android actual-device validation was explicitly removed from V5 acceptance because no device is available; this is recorded as WAIVED, not PASS. V5 Deliverable is Frozen. Any future Android validation is a separate device-validation Gate and does not reopen V5.
