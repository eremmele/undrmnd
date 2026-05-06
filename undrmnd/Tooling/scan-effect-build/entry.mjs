/**
 * Standalone Quantum Nebula (Framer Marketplace) — **Torus mode** defaults only.
 *
 * Glyph “u” was reverted: the vendor **Image/Hologram** path extrudes along one axis from 2D
 * luminance (`uExtrusion`), which reads as a needle—not torus‑like tubular volume without a full
 * 3D stencil / radial shell around strokes.
 *
 * Source: https://framer.com/m/QuantumNebula-ngIX.js → QuantumNebula.js (framerusercontent.com)
 * License: docs/third-party-quantum-nebula.md
 */
import * as THREE from "three";

const PROPS = {
  mode: "Torus",
  image: null,
  appearance: {
    /** Ink-on-paper torus for intro splash (AdditiveBlending swapped to NormalBlending below). */
    color1: "#0a0a0a",
    color2: "#3c3c3c",
    particleSize: 300,
  },
  geometry: {
    count: 8500,
    radiusMain: 25,
    radiusTube: 8,
    twist: 2,
  },
  hologram: {
    extrusion: 15,
    invertDepth: false,
  },
  animation: {
    speed: 0.54,
  },
  quality: -1,
};

function sanitizeColor(c) {
  if (!c) return new THREE.Color(0xffffff);
  if (typeof c === "string") {
    if (c.startsWith("#") && c.length === 9) {
      return new THREE.Color(c.substring(0, 7));
    }
    if (c.includes("rgba")) {
      const match = c.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
      if (match) {
        return new THREE.Color(
          `rgb(${match[1]}, ${match[2]}, ${match[3]})`
        );
      }
    }
  }
  return new THREE.Color(c);
}

function detectDeviceQuality() {
  if (typeof window === "undefined") return 1;
  const cores = navigator.hardwareConcurrency || 4;
  const memory = navigator.deviceMemory || 8;
  const isMobile =
    "ontouchstart" in window || navigator.maxTouchPoints > 0;
  const pixelRatio = window.devicePixelRatio || 1;
  if (cores <= 2 || memory <= 2 || (isMobile && pixelRatio > 2)) return 0;
  if (cores <= 4 || memory <= 4 || isMobile) return 1;
  return 2;
}

const vertexShader = `
    uniform float uTime;
    uniform float uSize;
    uniform float uSpeed;
    uniform float uMainRadius;
    uniform float uTubeRadius;
    uniform float uTwist;
    uniform vec2 uMouse;
    uniform float uMode; 
    uniform float uExtrusion;
    uniform float uInvertDepth;
    
    attribute vec2 aTorusUV;
    attribute float aRandom;
    attribute float aBrightness;
    
    varying float vRandom;
    varying float vDepth;
    varying float vBrightness;
    varying float vScan;

    void main() {
        vRandom = aRandom;
        vBrightness = aBrightness;
        
        vec3 pos = position;

        if (uMode < 0.5) {
            float u = aTorusUV.x + uTime * uSpeed * 0.5; 
            float v = aTorusUV.y + uTime * uSpeed * uTwist;

            float r = uTubeRadius + (sin(u * 4.0 + uTime) * 1.5);
            
            pos.x = (uMainRadius + r * cos(v)) * cos(u);
            pos.y = (uMainRadius + r * cos(v)) * sin(u);
            pos.z = r * sin(v);
        } else {
            float b = vBrightness;
            if(uInvertDepth > 0.5) b = 1.0 - b;

            float depth = b * uExtrusion;
            pos.z += depth;

            pos.z += sin(pos.x * 0.2 + uTime) * 0.5;
        }

        float tiltX = -uMouse.y * 0.5;
        float tiltY = uMouse.x * 0.5;
        
        float cx = cos(tiltX), sx = sin(tiltX);
        vec3 temp = pos;
        pos.y = temp.y * cx - temp.z * sx;
        pos.z = temp.y * sx + temp.z * cx;
        
        float cy = cos(tiltY), sy = sin(tiltY);
        temp = pos;
        pos.x = temp.x * cy - temp.z * sy;
        pos.z = temp.x * sy + temp.z * cy;

        if (uMode < 0.5) {
            float autoRot = uTime * 0.1;
            float ca = cos(autoRot), sa = sin(autoRot);
            temp = pos;
            pos.x = temp.x * ca - temp.y * sa;
            pos.y = temp.x * sa + temp.y * ca;
        }

        vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
        vDepth = -mvPosition.z;

        float scanPos = mod(uTime * 15.0, 120.0) - 60.0; 
        float distToScan = abs(pos.y - scanPos); 
        vScan = smoothstep(5.0, 0.0, distToScan); 
        
        float sizeMult = (uMode > 0.5) ? (0.5 + vBrightness * 1.5) : (0.8 + aRandom * 0.4);
        
        gl_PointSize = (uSize * sizeMult) / -mvPosition.z;
        if (-mvPosition.z < 1.0) gl_PointSize = 0.0;

        gl_Position = projectionMatrix * mvPosition;
    }
`;

const fragmentShader = `
    uniform sampler2D uTex;
    uniform float uCols;
    uniform vec3 uColor1;
    uniform vec3 uColor2;
    uniform float uTime;
    uniform float uCharSet; 
    uniform float uMode;

    varying float vRandom;
    varying float vDepth;
    varying float vBrightness;
    varying float vScan;

    void main() {
        float charTick = floor(uTime * 5.0 + vRandom * 10.0);
        float rowOffset = (uCharSet > 0.5) ? 8.0 : 0.0; 
        float charIndex = mod(charTick, 8.0) + (rowOffset * uCols) + floor(vRandom * 8.0);

        vec2 uv = gl_PointCoord;
        float charSize = 1.0 / uCols;
        float col = mod(charIndex, uCols);
        float row = floor(charIndex / uCols);
        vec2 charUV = vec2((col + uv.x) * charSize, 1.0 - ((row + 1.0 - uv.y) * charSize));

        vec4 tex = texture2D(uTex, charUV);
        if (tex.a < 0.45) discard;

        vec3 finalColor;

        if (uMode < 0.5) {
            float depthFactor = smoothstep(20.0, 90.0, vDepth);
            finalColor = mix(uColor1, uColor2, depthFactor);
            float highlight = step(0.97, sin(uTime * 14.0 + vRandom * 100.0));
            finalColor = mix(finalColor, vec3(0.52), highlight * 0.2);
        } else {
            float mixVal = vRandom * 0.3 + 0.2;
            finalColor = mix(uColor1, uColor2, mixVal);
            
            finalColor = mix(finalColor, vec3(1.0), vBrightness * vBrightness * 0.8);

            finalColor += vScan * vec3(0.5, 1.0, 1.0); 

            float scan = sin(gl_FragCoord.y * 0.3 + uTime * 10.0) * 0.1 + 0.9;
            finalColor *= scan;
        }

        gl_FragColor = vec4(finalColor, tex.a);
    }
`;

function createCharTexture() {
  /** Smaller atlas: faster Canvas2D warmup; sharp enough at NearestFilter for point sprites. */
  const size = 384;
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext("2d");
  if (!ctx) return null;
  const cols = 16;
  const charSize = size / cols;
  const glyphs = "01XYZ[]<>/";
  const hex = "0123456789ABCDEF";
  ctx.font = `bold ${charSize * 0.7}px monospace`;
  ctx.fillStyle = "white";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  for (let i = 0; i < cols * cols; i++) {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const x = col * charSize + charSize / 2;
    const y = row * charSize + charSize / 2;
    let char = "";
    if (row < 8) char = glyphs[Math.floor(Math.random() * glyphs.length)];
    else char = hex[Math.floor(Math.random() * hex.length)];
    ctx.fillText(char, x, y);
  }
  const tex = new THREE.CanvasTexture(canvas);
  tex.minFilter = THREE.NearestFilter;
  tex.magFilter = THREE.NearestFilter;
  return { texture: tex, cols };
}

function initTorusParticles(scene, material, props) {
  const count = props.geometry.count;
  const geometry = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  const uvGrid = new Float32Array(count * 2);
  const randomness = new Float32Array(count);
  const brightness = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    const u = Math.random();
    const v = Math.random();
    uvGrid[i * 2] = u * Math.PI * 2;
    uvGrid[i * 2 + 1] = v * Math.PI * 2;
    randomness[i] = Math.random();
    brightness[i] = 1;
  }
  geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute("aTorusUV", new THREE.BufferAttribute(uvGrid, 2));
  geometry.setAttribute("aRandom", new THREE.BufferAttribute(randomness, 1));
  geometry.setAttribute("aBrightness", new THREE.BufferAttribute(brightness, 1));
  const points = new THREE.Points(geometry, material);
  scene.add(points);
  return points;
}

function initImageParticles(scene, material, imageUrl, onFail) {
  const img = new Image();
  img.crossOrigin = "Anonymous";
  img.onload = () => {
    const width = 250;
    const scale = 0.18;
    const iCan = document.createElement("canvas");
    const iCtx = iCan.getContext("2d");
    if (!iCtx) {
      onFail?.();
      return;
    }
    const aspect = img.width / img.height;
    const h = width / aspect;
    iCan.width = width;
    iCan.height = h;
    iCtx.drawImage(img, 0, 0, width, h);
    const imgData = iCtx.getImageData(0, 0, width, h).data;
    const validPixels = [];
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < width; x++) {
        const i = (y * width + x) * 4;
        const a = imgData[i + 3];
        if (a > 40) {
          const r = imgData[i];
          const g = imgData[i + 1];
          const bVal = imgData[i + 2];
          const brit = (r * 0.299 + g * 0.587 + bVal * 0.114) / 255;
          const px = (x - width / 2) * scale;
          const py = -(y - h / 2) * scale;
          validPixels.push({ x: px, y: py, z: 0, b: brit });
        }
      }
    }
    const count = validPixels.length;
    if (count < 8) {
      onFail?.();
      return;
    }
    const positions = new Float32Array(count * 3);
    const randomness = new Float32Array(count);
    const bright = new Float32Array(count);
    const uvGrid = new Float32Array(count * 2);
    for (let i = 0; i < count; i++) {
      const p = validPixels[i];
      positions[i * 3] = p.x;
      positions[i * 3 + 1] = p.y;
      positions[i * 3 + 2] = p.z;
      bright[i] = p.b;
      randomness[i] = Math.random();
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute("aRandom", new THREE.BufferAttribute(randomness, 1));
    geometry.setAttribute("aBrightness", new THREE.BufferAttribute(bright, 1));
    geometry.setAttribute("aTorusUV", new THREE.BufferAttribute(uvGrid, 2));
    const points = new THREE.Points(geometry, material);
    scene.add(points);
  };
  img.onerror = () => onFail?.();
  img.src = imageUrl;
}

(() => {
  const mouseRef = new THREE.Vector2(0, 0);
  const targetMouseRef = new THREE.Vector2(0, 0);

  function setTargetFromClient(clientX, clientY) {
    const w = window.innerWidth;
    const h = Math.max(window.innerHeight, 1);
    const x = (clientX / w) * 2 - 1;
    const y = -((clientY / h) * 2 - 1);
    targetMouseRef.set(x, y);
  }

  window.addEventListener("mousemove", (e) => {
    setTargetFromClient(e.clientX, e.clientY);
  });
  window.addEventListener(
    "touchmove",
    (e) => {
      if (e.touches?.length > 0) {
        const t = e.touches[0];
        setTargetFromClient(t.clientX, t.clientY);
      }
    },
    { passive: true }
  );

  const effectiveQuality =
    PROPS.quality === -1 ? detectDeviceQuality() : PROPS.quality;

  const pixelRatioMap = {
    0: 1,
    1: Math.min(window.devicePixelRatio || 1, 1.35),
    2: Math.min(window.devicePixelRatio || 1, 1.65),
  };
  const targetPixelRatio = pixelRatioMap[effectiveQuality] ?? 1.5;

  const adaptiveParticleCount =
    effectiveQuality <= 0
      ? Math.min(PROPS.geometry.count, 3800)
      : effectiveQuality === 1
        ? Math.min(PROPS.geometry.count, 6400)
        : PROPS.geometry.count;
  const propsWithCount = {
    ...PROPS,
    geometry: { ...PROPS.geometry, count: adaptiveParticleCount },
  };

  const scene = new THREE.Scene();
  scene.background = null;
  scene.fog = null;

  const camera = new THREE.PerspectiveCamera(65, 1, 0.1, 1000);
  camera.position.set(0, 0, 60);

  const renderer = new THREE.WebGLRenderer({
    alpha: true,
    antialias: false,
    powerPreference:
      effectiveQuality < 1 ? "low-power" : "high-performance",
  });
  renderer.setPixelRatio(targetPixelRatio);
  renderer.setClearColor(0, 0);
  document.body.appendChild(renderer.domElement);

  Object.assign(renderer.domElement.style, {
    position: "absolute",
    inset: "0",
    width: "100%",
    height: "100%",
    display: "block",
    background: "transparent",
  });

  const charPack = createCharTexture();
  if (!charPack) {
    document.getElementById("loading")?.classList.add("hidden");
    try {
      window.webkit?.messageHandlers?.scanBackgroundReady?.postMessage("0");
    } catch (_) {}
    return;
  }

  const material = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uTex: { value: charPack.texture },
      uCols: { value: charPack.cols },
      uSize: { value: PROPS.appearance.particleSize },
      uSpeed: { value: PROPS.animation.speed },
      uMainRadius: { value: PROPS.geometry.radiusMain },
      uTubeRadius: { value: PROPS.geometry.radiusTube },
      uTwist: { value: PROPS.geometry.twist },
      uMouse: { value: mouseRef },
      uColor1: { value: sanitizeColor(PROPS.appearance.color1) },
      uColor2: { value: sanitizeColor(PROPS.appearance.color2) },
      uCharSet: { value: 0 },
      uMode: { value: PROPS.mode === "Torus" ? 0 : 1 },
      uExtrusion: { value: PROPS.hologram.extrusion },
      uInvertDepth: { value: PROPS.hologram.invertDepth ? 1 : 0 },
    },
    vertexShader,
    fragmentShader,
    transparent: true,
    blending: THREE.NormalBlending,
    depthWrite: false,
  });

  let pointsRef = null;

  if (PROPS.mode === "Torus") {
    pointsRef = initTorusParticles(scene, material, propsWithCount);
  } else if (PROPS.mode === "Image" && PROPS.image) {
    initImageParticles(scene, material, PROPS.image, () => {
      document.getElementById("loading")?.classList.add("hidden");
      try {
        window.webkit?.messageHandlers?.scanBackgroundReady?.postMessage("0");
      } catch (_) {}
    });
  } else {
    pointsRef = initTorusParticles(scene, material, propsWithCount);
  }

  function handleResize() {
    const width = window.innerWidth;
    const height = Math.max(window.innerHeight, 1);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
  }

  handleResize();
  window.addEventListener("resize", handleResize);

  let time = 0;
  let frameId;
  let frames = 0;
  /** ~2 RAF passes: WKWebKit compiles programs on first draws; avoids multi-second idle gates. */
  const minFramesBeforeReveal = 2;
  let didReveal = false;

  let revealSafetyT = null;

  function revealWhenReady() {
    if (didReveal) return;
    didReveal = true;
    if (revealSafetyT != null) clearTimeout(revealSafetyT);
    document.getElementById("loading")?.classList.add("hidden");
    try {
      window.webkit?.messageHandlers?.scanBackgroundReady?.postMessage("1");
    } catch (_) {}
  }

  function animate() {
    frameId = requestAnimationFrame(animate);
    time += 0.01;
    mouseRef.lerp(targetMouseRef, 0.05);
    material.uniforms.uTime.value = time;
    material.uniforms.uMouse.value.copy(mouseRef);
    renderer.clear();
    renderer.render(scene, camera);
    frames += 1;
    if (frames >= minFramesBeforeReveal) revealWhenReady();
  }

  animate();

  /** Last-resort unblock if WebGL/context never paints (still far below the old ~9s minimum). */
  revealSafetyT = setTimeout(revealWhenReady, 720);

  window.addEventListener("beforeunload", () => {
    cancelAnimationFrame(frameId);
    clearTimeout(revealSafetyT);
    charPack.texture.dispose();
    material.dispose();
    if (pointsRef?.geometry) pointsRef.geometry.dispose();
  });
})();
