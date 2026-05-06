# Quantum Nebula (Framer Marketplace)

**Purchased component license ID:** `42730CC1-B15E-4628-B785-B0C84B8D6634`

The intro bundle is **standalone Three.js** (`Tooling/scan-effect-build/entry.mjs` → `Resources/ScanEffect/scan-effect-bundle.js`); it does **not** embed React or the Framer runtime.

**Behavior:** Matches the marketplace module **`addPropertyControls` defaults** with **`mode: "Torus"`**: documented colors/size/count/radii/twist/speed, vendor vertex/fragment shaders, char atlas, **`time += 0.01`**, mouse **`.lerp(..., 0.05)`**, transparent renderer, quality/pixel ratio, **`PerspectiveCamera(65)`** at **`(0,0,60)`**, additive points, no bloom.

The intro screen uses **Torus** only (`Image` hologram extrusion differs from tubular torus geometry; revisiting **MD Lorien `u`** would need a radial/tube displacement around sampled strokes—not the stock **`uExtrusion`** depth map).

**Canonical URLs**

1. [QuantumNebula-ngIX.js](https://framer.com/m/QuantumNebula-ngIX.js) → re-exports…
2. [QuantumNebula.js](https://framerusercontent.com/modules/EidWreQYvafYE61HK2MP/F55EU4YfPbGBrjF58p17/QuantumNebula.js)


## Vendor documentation

**Component:** Quantum Nebula — Advanced 3D particle system with Torus and Hologram modes. Renders on a transparent canvas so a parent layer fill shows behind the particles.

| Item | URL |
|------|-----|
| Component URL | [Quantum Nebula ngIX](https://framer.com/m/QuantumNebula-ngIX.js) |
| Canonical module JS | [QuantumNebula.js (hosted)](https://framerusercontent.com/modules/EidWreQYvafYE61HK2MP/F55EU4YfPbGBrjF58p17/QuantumNebula.js) |
| Marketplace listing | https://www.framer.com/marketplace/components/quantumnebula/ |
| Demo | https://enlivened-takeaways-773470.framer.app/ |

**Support:** https://x.com/Shahul_the_dev · shahul@amazee.studio

---

## Quick tips (from supplier docs)

- **View modes:** Torus (procedural shapes) vs Image (“hologram” from image).
- **Transparent background:** The Framer component does not paint its own background; rely on frame/section fill.
- **Particle count:** Higher density = more GPU; start with defaults.
- **Performance:** WebGL-backed; supplier recommends Auto quality where available.

---

## Controls reference (Framer UI)

| Group | Control | Description |
|-------|---------|----------------|
| — | View Mode | Torus or Image |
| Appearance | Primary Color | Main particle color |
| Appearance | Secondary Color | Accent |
| Appearance | Particle Size | Point sprite size |
| Geometry | Radius | Torus outer radius |
| Geometry | Tube | Tube thickness |
| Geometry | Twist | Spiral twist |
| Geometry | Count | Particle count |
| Hologram | Image | Source image |
| Hologram | Extrusion | Depth |
| Hologram | Invert | Invert brightness |
| Animation | Flow Speed | Motion speed |
| — | Quality | Auto, Performance, Balanced, Quality |
