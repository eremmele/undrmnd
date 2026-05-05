/**
 * Intro background: layered particle nebula (no video). Same pointer field for mouse / touch —
 * unified NDC coords so touch follows the streak the way mouse-follow does on desktop.
 * Not derived from marketplace components; mindful motion only (respects prefers-reduced-motion).
 */
import * as THREE from "three";
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer.js";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass.js";

(async () => {
  const reduceMotion =
    typeof window !== "undefined" &&
    window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches;

  /** Pointer in normalized screen space: x,y in [0,1], strength 0..1. */
  const pointerUv = new THREE.Vector2(0.5, 0.5);
  let pointerStrength = 0;

  function setPointerFromClient(clientX, clientY) {
    pointerUv.x = clientX / window.innerWidth;
    pointerUv.y = 1 - clientY / Math.max(window.innerHeight, 1);
  }

  window.addEventListener(
    "touchstart",
    (e) => {
      pointerStrength = 1;
      if (e.touches?.length > 0) {
        const t = e.touches[0];
        setPointerFromClient(t.clientX, t.clientY);
      }
    },
    { passive: true }
  );
  window.addEventListener(
    "touchmove",
    (e) => {
      if (e.touches?.length > 0) {
        const t = e.touches[0];
        pointerStrength = 1;
        setPointerFromClient(t.clientX, t.clientY);
      }
    },
    { passive: true }
  );
  window.addEventListener("touchend", () => {
    pointerStrength = 0;
  }, { passive: true });
  window.addEventListener("touchcancel", () => {
    pointerStrength = 0;
  }, { passive: true });

  window.addEventListener("mousemove", (e) => {
    pointerStrength = 1;
    setPointerFromClient(e.clientX, e.clientY);
  });
  window.addEventListener("mouseleave", () => {
    pointerStrength = 0;
  });

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x04040a);

  const camera = new THREE.PerspectiveCamera(
    52,
    window.innerWidth / Math.max(window.innerHeight, 1),
    0.08,
    80
  );
  camera.position.z = 6.2;

  const renderer = new THREE.WebGLRenderer({
    antialias: false,
    powerPreference: "default",
    failIfMajorPerformanceCaveat: false,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  document.body.appendChild(renderer.domElement);

  const raycaster = new THREE.Raycaster();
  const planeZ = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0);
  const planeHit = new THREE.Vector3();
  const ndc = new THREE.Vector2();

  function targetOnPlane() {
    ndc.x = pointerUv.x * 2 - 1;
    ndc.y = pointerUv.y * 2 - 1;
    raycaster.setFromCamera(ndc, camera);
    if (raycaster.ray.intersectPlane(planeZ, planeHit)) return planeHit;
    return null;
  }

  const area = window.innerWidth * window.innerHeight;
  const n = reduceMotion
    ? 1400
    : window.innerWidth < 420
      ? 3200
      : Math.min(8800, Math.floor(area / 420));

  const positions = new Float32Array(n * 3);
  const rest = new Float32Array(n * 3);
  const vel = new Float32Array(n * 3);
  const phase = new Float32Array(n);
  const hueJ = new Float32Array(n);

  const spreadX = 7.2;
  const spreadY = 10.5;
  const spreadZ = 4.2;

  for (let i = 0; i < n; i++) {
    const i3 = i * 3;
    const x = (Math.random() - 0.5) * spreadX;
    const y = (Math.random() - 0.5) * spreadY;
    const z = (Math.random() - 0.5) * spreadZ;
    positions[i3] = x;
    positions[i3 + 1] = y;
    positions[i3 + 2] = z;
    rest[i3] = x;
    rest[i3 + 1] = y;
    rest[i3 + 2] = z;
    phase[i] = Math.random() * Math.PI * 2;
    hueJ[i] = Math.random();
  }

  const geom = new THREE.BufferGeometry();
  geom.setAttribute("position", new THREE.BufferAttribute(positions, 3));
  geom.setAttribute("aPhase", new THREE.BufferAttribute(phase, 1));
  geom.setAttribute("aHueJ", new THREE.BufferAttribute(hueJ, 1));

  const material = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uPointScale: { value: reduceMotion ? 1.2 : 1.55 },
    },
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    vertexShader: `
      uniform float uTime;
      uniform float uPointScale;
      attribute float aPhase;
      attribute float aHueJ;
      varying float vAlpha;
      varying vec3 vColor;

      void main() {
        vec4 mv = modelViewMatrix * vec4(position, 1.0);
        float tw = uTime * (0.35 + aHueJ * 0.25);
        float pulse = 0.78 + 0.22 * sin(tw + aPhase);
        vAlpha = 0.22 + 0.55 * pulse * (0.35 + aHueJ);

        vec3 deep = vec3(0.28, 0.38, 1.0);
        vec3 aqua = vec3(0.42, 0.85, 1.0);
        vec3 mist = vec3(0.88, 0.92, 1.0);
        vColor = mix(mix(deep, aqua, aHueJ), mist, 0.18 + 0.25 * pulse);

        gl_PointSize = uPointScale * (220.0 / -mv.z) * (0.75 + aHueJ * 0.8);
        gl_Position = projectionMatrix * mv;
      }
    `,
    fragmentShader: `
      precision highp float;
      varying float vAlpha;
      varying vec3 vColor;
      void main() {
        vec2 q = gl_PointCoord * 2.0 - 1.0;
        float r = dot(q, q);
        if (r > 1.0) discard;
        float soft = pow(1.0 - r, 2.2);
        gl_FragColor = vec4(vColor, vAlpha * soft);
      }
    `,
  });

  const points = new THREE.Points(geom, material);
  scene.add(points);

  const composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));
  composer.addPass(
    new UnrealBloomPass(
      new THREE.Vector2(window.innerWidth, window.innerHeight),
      reduceMotion ? 0.45 : 0.72,
      0.36,
      0.72
    )
  );

  const clock = new THREE.Clock();
  const posAttr = geom.getAttribute("position");

  let frames = 0;
  const minFramesBeforeReveal = reduceMotion ? 4 : 10;
  let didReveal = false;

  function revealWhenReady() {
    if (didReveal) return;
    didReveal = true;
    document.getElementById("loading")?.classList.add("hidden");
    try {
      window.webkit?.messageHandlers?.scanBackgroundReady?.postMessage("1");
    } catch (_) {}
  }

  function resize() {
    const w = window.innerWidth;
    const h = Math.max(window.innerHeight, 1);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
    renderer.setSize(w, h);
    composer.setSize(w, h);
  }
  window.addEventListener("resize", resize);

  setTimeout(() => {
    revealWhenReady();
  }, 9000);

  function animate() {
    requestAnimationFrame(animate);
    const dt = Math.min(clock.getDelta(), 0.05);
    const t = clock.elapsedTime;
    material.uniforms.uTime.value = t;

    const target = pointerStrength > 0.02 ? targetOnPlane() : null;

    const pull = pointerStrength > 0.02 ? 12.8 * pointerStrength : 0;
    const damp = reduceMotion ? 0.965 : 0.988;
    const restK = reduceMotion ? 0.032 : 0.055;
    const idleAmp = reduceMotion ? 0.012 : 0.055;

    for (let i = 0; i < n; i++) {
      const i3 = i * 3;
      let px = posAttr.array[i3];
      let py = posAttr.array[i3 + 1];
      let pz = posAttr.array[i3 + 2];

      const rx = rest[i3];
      const ry = rest[i3 + 1];
      const rz = rest[i3 + 2];

      let ax =
        Math.sin(t * 0.38 + phase[i]) * idleAmp -
        restK * (px - rx);
      let ay =
        Math.cos(t * 0.31 + phase[i] * 1.1) * idleAmp -
        restK * (py - ry);
      let az =
        Math.sin(t * 0.22 + hueJ[i]) * idleAmp * 0.85 -
        restK * (pz - rz);

      if (target) {
        const dx = target.x - px;
        const dy = target.y - py;
        const dz = target.z - pz;
        const d2 = dx * dx + dy * dy + dz * dz + 0.45;
        const f = pull / d2;
        ax += dx * f;
        ay += dy * f;
        az += dz * f * 0.55;
      }

      vel[i3] = (vel[i3] + ax * dt * 62) * damp;
      vel[i3 + 1] = (vel[i3 + 1] + ay * dt * 62) * damp;
      vel[i3 + 2] = (vel[i3 + 2] + az * dt * 62) * damp;

      posAttr.array[i3] = px + vel[i3] * dt * 52;
      posAttr.array[i3 + 1] = py + vel[i3 + 1] * dt * 52;
      posAttr.array[i3 + 2] = pz + vel[i3 + 2] * dt * 52;
    }

    posAttr.needsUpdate = true;

    composer.render();
    frames += 1;
    if (frames >= minFramesBeforeReveal) revealWhenReady();
  }
  animate();
})().catch(() => {
  document.getElementById("loading")?.classList.add("hidden");
  try {
    window.webkit?.messageHandlers?.scanBackgroundReady?.postMessage("0");
  } catch (_) {}
});
