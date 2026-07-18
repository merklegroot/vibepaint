# Studio Brush Live Stroke Strategies

Research notes on how other painting apps handle live stroke preview, taper, and ink
accumulation behind the drawing lead. Written to guide VibePaint studio brush behavior.

## The problem

When a live stroke preview re-rasterizes the full path on every frame, **end-of-stroke
taper** is recomputed from total arc length. As the stroke grows:

1. Points that were at the moving tip had a small `distanceFromEnd` → thin/light.
2. New points extend the stroke → those older points get a larger `distanceFromEnd`.
3. Their end taper multiplier rises toward 1.0 → they become thicker/darker.
4. Visually, ink **fills in behind the lead** while drawing.

This is separate from preview lightness caused by baking stamps into an image vs painting
directly. The root cause here is **retroactive end taper**.

## Strategy 1: Incremental dabs (MyPaint / libmypaint)

**Source:** [libmypaint wiki — Using Brushlib](https://github.com/mypaint/libmypaint/wiki/Using-Brushlib)

- Each pointer event calls `stroke_to()`, which places dabs on the surface immediately.
- Dab radius, opacity, and spacing come from filtered inputs (pressure, speed, random).
- **No full-stroke re-render.** Once a dab is written, it is never recomputed.
- Overlap density is achieved by many semi-transparent dabs (`opaque` tuned per brush).

**Pros:** Stable trail while drawing; predictable performance (cost per dab, not per stroke
length). **Cons:** Stroke-local effects that depend on total length must be handled
carefully (see taper strategies below).

**VibePaint mapping:** Keep incremental raster preview; append only new stamp indices each
sync. Never re-rasterize the body of an in-progress stroke.

## Strategy 2: Deferred end taper (Procreate — Tip Animation Off)

**Sources:**

- [Procreate Handbook — Taper / Tip Animation](https://help.procreate.com/procreate/handbook/brushes/brush-studio-settings)
- [Adventures with Art — Procreate taper guide](https://adventureswithart.com/procreate-brush-taper-settings/)

Procreate exposes **Tip Animation**:

- **Off:** End taper is applied when you **lift** the stylus, not while the stroke is
  growing.
- **On:** End taper is visible at the moving tip **as you draw**.

With Tip Animation off, the stroke body stays stable during input. Only the finalized
stroke gets the trailing fade. This avoids retroactive darkening behind the cursor.

**VibePaint mapping (default):**

| Phase | Start taper | End taper | Render mode |
|-------|-------------|-----------|-------------|
| Live (in-progress) | Yes | **No** | Incremental append |
| Committed (in history) | Yes | Yes | Full stroke paint |

Start taper is safe during live preview because `distanceFromStart` is fixed per point.

## Strategy 3: Moving-tip taper only (Procreate — Tip Animation On)

**Source:** Same Procreate taper docs.

End taper is shown only in a short window at the **current** trailing tip. The taper
region moves with the cursor. Points that leave that window should **not** be
re-darkened on every frame.

**Requirements:**

- Incremental dab placement only (Strategy 1).
- End taper evaluated **only for newly added points**, using distance from the then-current
  last point.
- Do **not** re-run end taper on earlier points when the stroke lengthens.

**Trade-off:** Points that were drawn thin at the tip may still be thin in the preview
until commit. On commit, a full render applies the final end taper only to the true stroke
end (last `endTaperLengthFactor × brushSize`).

## Strategy 4: Frame-throttled preview sync (MyPaint overload feedback)

**Source:** [MyPaint bug #14094 — CPU overload feedback](https://www.mail-archive.com/mypaint-bugs@gna.org/msg03654.html)

When rendering cannot keep up with input, MyPaint queues events and renders in idle
chunks. The brush may trail the cursor — a deliberate overload signal.

**VibePaint mapping:**

- Coalesce preview rebuilds to one per frame (`scheduleFrameCallback`).
- Avoid full-stroke re-rasterize on every pointer move.
- Prefer incremental append within that frame budget.

## Strategy 5: LOD / proxy preview (Krita Instant Preview)

**Source:** [Krita Manual — Instant Preview](https://userbase.kde.org/Krita/Manual/BrushEngines/InstantPreview)

Krita paints a lower-resolution proxy while the real stroke computes in the background.
Some brush settings (auto-spacing, fuzzy size, textures) cause a visible “pop” when the
final stroke replaces the proxy.

**VibePaint mapping:** Not needed at current canvas sizes. If adopted later, the proxy
must use the **same** taper phase rules as live mode so the pop is only resolution, not
opacity.

## Strategy 6: Direct canvas paint for live stroke (no raster cache)

Paint the in-progress stroke with the same stamp path as commit, skipping the offscreen
`ui.Image` step. Guarantees identical compositing, but replays all stamps every repaint
unless combined with Strategy 1.

**VibePaint mapping:** Fallback if incremental image compositing still diverges. Higher CPU
cost on long strokes.

## Recommended combination for VibePaint

1. **Incremental append** for live preview (Strategy 1).
2. **Deferred end taper** during live phase (Strategy 2) — matches Procreate default
   expectations and fixes fill-in behind the lead.
3. **Full start + end taper** on commit (Strategy 2).
4. **Frame-throttled sync** (Strategy 4).

Optional future work: user-toggle “tip animation” (Strategy 3) for live end taper at the
moving tip only, still without retroactive body re-rasterize.

## Implementation checklist

- [ ] `StudioBrushStrokePhase.live` disables end taper in stamp renderer.
- [ ] `StudioBrushStrokePhase.committed` enables full taper (current behavior).
- [ ] Preview rasterizer appends only new point indices.
- [ ] Preview sync runs at frame boundary, not on every pointer event.
- [ ] Tests: live phase does not apply end taper; committed phase does.
