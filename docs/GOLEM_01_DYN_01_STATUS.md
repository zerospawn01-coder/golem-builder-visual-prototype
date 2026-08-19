# GOLEM-01-DYN-01 Status

## Static regression

The first DYN-01 gate rechecks the existing GOLEM-01 part masters under the frozen Compatibility renderer:

```text
TORSO       PASS
PELVIS      PASS
CORE        PASS
LEFT THIGH  PASS
RIGHT THIGH PASS
```

The machine gate verifies the renderer settings, PNG loadability, exact alpha counts, audit verdicts, checkerboard separation, and TORSO/PELVIS/CORE connection contracts. It does not claim hip or knee articulation.

## Dynamic gates

### HIP neutral — PASS

The first articulation slice uses a pelvis-socket-based `LeftHipPivot` and a child `LeftThighSprite`. The Sprite uses an attachment offset and keeps `rotation = 0`; only the parent pivot is permitted to rotate. Neutral coordinate regression and runtime texture resolution pass under the Compatibility renderer, while forward/back evidence is still pending.

```text
HIP neutral                   PASS
HIP forward / back            PASS (exploration bounds +45 / -20 degrees)
KNEE partial / deep           NOT STARTED
ground contact                NOT STARTED
PC / Mobile dynamic review   NOT STARTED
```

The DYN-01 verdict remains `INCOMPLETE` until the dynamic checks and the 9:16 mobile viewport evidence are complete.
