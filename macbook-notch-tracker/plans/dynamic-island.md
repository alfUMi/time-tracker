# FULL REWRITE REQUIRED - Dynamic Island Architecture

## IMPORTANT

Do not modify the current implementation.

Do not improve the current implementation.

Do not refactor the current implementation.

Assume the current Dynamic Island implementation is architecturally incorrect and must be replaced.

Your task is to completely redesign and rebuild the Dynamic Island system from scratch.

---

# PRIMARY GOAL

Create a Dynamic Island experience for MacBook notch displays that visually appears to be part of the physical notch itself.

The final result should be comparable to professional notch applications.

The user should perceive the notch and the Dynamic Island as a single object.

---

# FIRST STEP (MANDATORY)

Before writing any code:

1. Analyze the entire existing Dynamic Island implementation.
2. Explain why the current implementation fails.
3. Identify every architectural decision that creates:

   * a floating panel effect
   * incorrect positioning
   * incorrect geometry
   * incorrect animation behavior
   * incorrect notch integration
4. List every component that should be deleted.

Do not write replacement code until this report is complete.

---

# HARD REQUIREMENT

The Dynamic Island must not be implemented as:

* a popup
* a dropdown
* a floating panel
* a sheet
* a card
* a toolbar
* a detached overlay

If the result visually resembles any of the above, the implementation is considered a failure.

---

# NOTCH GEOMETRY

The closed state must replicate the actual notch geometry.

Requirements:

* Top edge must touch the top edge of the display
* No visible gap above the island
* No visible margin
* No floating effect
* No capsule shape
* No pill shape

The island must inherit the geometry of the physical notch.

The top edge should appear fused with the screen edge.

The lower corners should match the notch style.

The closed state should appear indistinguishable from the notch.

---

# POSITIONING

The notch is the origin point of the entire system.

All coordinates must be calculated relative to:

* active display
* menu bar position
* notch position

The island must always remain perfectly centered on the notch.

Hardcoded offsets are forbidden.

Hardcoded coordinates are forbidden.

Magic numbers are forbidden.

---

# WINDOW SYSTEM

Create a dedicated overlay architecture.

Requirements:

* borderless window
* transparent background
* no title bar
* no visible frame
* no standard macOS window appearance

The window exists only as a rendering surface.

Users must never perceive a window.

---

# CLOSED STATE

Default state after launch.

Requirements:

* visually identical to notch
* minimal dimensions
* attached to screen edge
* no content visible
* no controls visible
* no permanent expansion

The application should appear inactive.

---

# EXPANDED STATE

Expansion must originate from the notch geometry.

Forbidden:

* panel appearing below notch
* window sliding down
* card animation
* fade-in popup

Required:

* geometric morphing
* smooth width growth
* smooth height growth
* notch transforms into island

The animation must feel like the notch itself is changing shape.

---

# SHAPE SYSTEM

Implement a dedicated geometry engine.

States:

1. Hidden
2. Notch
3. Compact Island
4. Expanded Island

The system must interpolate between shapes.

Do not swap views.

Do not replace one component with another.

Morph geometry continuously.

---

# INTERACTION

Hover:

* subtle response
* optional compact expansion

Click:

* expand island

Outside click:

* collapse island

Idle timeout:

* return to notch state

The island should spend most of its lifetime in notch state.

---

# VISUAL REQUIREMENTS

No shadows used to hide mistakes.

No fake borders.

No hacks to conceal incorrect geometry.

No manual offsets to compensate for bad positioning.

The geometry itself must be correct.

---

# VALIDATION

Before finalizing implementation verify:

1. Does the closed state touch the top edge of the display?
2. Does the closed state visually match the notch?
3. Can the user distinguish the notch from the software?
4. Does expansion originate from the notch?
5. Does the island spend most of its time collapsed?
6. Does any part of the UI resemble a floating panel?

If any answer is incorrect, redesign the architecture before continuing.

---

# SUCCESS CRITERIA

A user looking at the screen should initially believe the Dynamic Island is the physical notch.

Only after interaction should they realize the notch is interactive.

If the user immediately sees a floating UI element, the implementation has failed.
