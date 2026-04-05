import * as THREE from "three";
import { EffectComposer } from "three/examples/jsm/postprocessing/EffectComposer.js";
import { RenderPass } from "three/examples/jsm/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/examples/jsm/postprocessing/UnrealBloomPass.js";

// IIFE for WKWebView: video + scan shader, cover UVs, touch scan spotlight. Ready = decoded frames + buffer + WebGL warm-up.
(async () => {
  const scene = new THREE.Scene();
  const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 10);
  camera.position.z = 1;
  const renderer = new THREE.WebGLRenderer({
    antialias: false,
    powerPreference: "default",
    failIfMajorPerformanceCaveat: false,
  });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 1.5));
  document.body.appendChild(renderer.domElement);

  const video = document.createElement("video");
  video.src = "./video.mp4";
  video.muted = true;
  video.loop = true;
  video.playsInline = true;
  video.setAttribute("playsinline", "");
  video.setAttribute("webkit-playsinline", "");
  video.preload = "auto";

  try {
    await new Promise((resolve, reject) => {
      video.addEventListener("canplaythrough", resolve, { once: true });
      video.addEventListener("error", reject, { once: true });
      video.load();
    });
    await video.play();
  } catch (_) {}

  const videoTexture = new THREE.VideoTexture(video);
  videoTexture.colorSpace = THREE.SRGBColorSpace;
  videoTexture.minFilter = THREE.LinearFilter;
  videoTexture.magFilter = THREE.LinearFilter;

  const touchUv = new THREE.Vector2(0.5, 0.5);
  let touchStrength = 0;

  function setTouchUvFromClient(clientX, clientY) {
    const w = window.innerWidth;
    const h = window.innerHeight;
    if (w <= 0 || h <= 0) return;
    touchUv.x = clientX / w;
    touchUv.y = 1.0 - clientY / h;
  }

  window.addEventListener(
    "touchstart",
    (e) => {
      touchStrength = 1;
      if (e.touches.length > 0) {
        const t = e.touches[0];
        setTouchUvFromClient(t.clientX, t.clientY);
      }
    },
    { passive: true }
  );
  window.addEventListener(
    "touchmove",
    (e) => {
      if (e.touches.length > 0) {
        const t = e.touches[0];
        setTouchUvFromClient(t.clientX, t.clientY);
      }
    },
    { passive: true }
  );
  window.addEventListener("touchend", () => { touchStrength = 0; }, { passive: true });
  window.addEventListener("touchcancel", () => { touchStrength = 0; }, { passive: true });

  const vw = video.videoWidth > 0 ? video.videoWidth : 804;
  const vh = video.videoHeight > 0 ? video.videoHeight : 1748;
  const sw = window.innerWidth;
  const sh = window.innerHeight;

  const material = new THREE.ShaderMaterial({
    uniforms: {
      uMap: { value: videoTexture },
      uProgress: { value: 0.0 },
      uTexelSize: { value: new THREE.Vector2(1 / vw, 1 / vh) },
      uScanWidth: { value: 0.028 },
      uViewAspect: { value: sh > 0 ? sw / sh : 1.0 },
      uVideoAspect: { value: vh > 0 ? vw / vh : 1.0 },
      uTouchUv: { value: new THREE.Vector2(0.5, 0.5) },
      uTouchStrength: { value: 0.0 },
    },
    vertexShader: `
    varying vec2 vUv;
    void main(){ vUv=uv; gl_Position=vec4(position,1.0); }
  `,
    fragmentShader: `
    precision highp float;
    uniform sampler2D uMap;
    uniform float uProgress;
    uniform vec2 uTexelSize;
    uniform float uScanWidth;
    uniform float uViewAspect;
    uniform float uVideoAspect;
    uniform vec2 uTouchUv;
    uniform float uTouchStrength;
    varying vec2 vUv;

    vec2 coverUv(vec2 uv) {
      float sa = uViewAspect;
      float va = max(uVideoAspect, 0.0001);
      float eps = 0.0005;
      if (abs(sa - va) < eps) return uv;
      if (sa > va) {
        float s = sa / va;
        uv.x = (uv.x - 0.5) / s + 0.5;
      } else {
        float s = va / sa;
        uv.y = (uv.y - 0.5) / s + 0.5;
      }
      return uv;
    }

    float luma(vec3 c) {
      return dot(c, vec3(0.299, 0.587, 0.114));
    }

    float sobelEdge(vec2 uv) {
      vec2 ts = uTexelSize * 2.0;
      float tl = luma(texture2D(uMap, uv + vec2(-ts.x, ts.y)).rgb);
      float t  = luma(texture2D(uMap, uv + vec2(0.0, ts.y)).rgb);
      float tr = luma(texture2D(uMap, uv + vec2(ts.x, ts.y)).rgb);
      float l  = luma(texture2D(uMap, uv + vec2(-ts.x, 0.0)).rgb);
      float r  = luma(texture2D(uMap, uv + vec2(ts.x, 0.0)).rgb);
      float bl = luma(texture2D(uMap, uv + vec2(-ts.x, -ts.y)).rgb);
      float b  = luma(texture2D(uMap, uv + vec2(0.0, -ts.y)).rgb);
      float br = luma(texture2D(uMap, uv + vec2(ts.x, -ts.y)).rgb);
      float gx = -tl - 2.0*l - bl + tr + 2.0*r + br;
      float gy = -tl - 2.0*t - tr + bl + 2.0*b + br;
      return sqrt(gx*gx + gy*gy);
    }

    vec3 screenBlend(vec3 base, vec3 blend) {
      return 1.0 - (1.0 - base) * (1.0 - blend);
    }

    void main() {
      vec2 uv = coverUv(vUv);
      vec3 raw = texture2D(uMap, uv).rgb;
      float depth = pow(luma(raw), 0.7);
      vec3 color = raw * 0.5;
      float edge = clamp(sobelEdge(uv) * 5.0, 0.0, 1.0);
      float flatArea = 1.0 - edge;
      float flow = 1.0 - smoothstep(0.0, uScanWidth, abs(depth - uProgress));

      float touchSpot = 1.0;
      if (uTouchStrength > 0.001) {
        vec2 d = vUv - uTouchUv;
        float r2 = dot(d, d);
        touchSpot = 1.0 + uTouchStrength * 2.4 * exp(-r2 * 58.0);
      }

      vec3 mask = vec3(flatArea) * flow * vec3(7.0, 7.0, 7.0) * touchSpot;
      vec3 result = screenBlend(color, mask);
      gl_FragColor = vec4(result, 1.0);
    }
  `,
  });

  function updateAspectUniforms() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    if (h > 0) material.uniforms.uViewAspect.value = w / h;
    const iw = video.videoWidth;
    const ih = video.videoHeight;
    if (ih > 0) material.uniforms.uVideoAspect.value = iw / ih;
  }

  const updateTexelFromVideo = () => {
    const w = video.videoWidth;
    const h = video.videoHeight;
    if (w > 0 && h > 0) {
      material.uniforms.uTexelSize.value.set(1 / w, 1 / h);
      material.uniforms.uVideoAspect.value = w / h;
    }
  };
  video.addEventListener("loadeddata", () => {
    updateTexelFromVideo();
    updateAspectUniforms();
  });

  const quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), material);
  scene.add(quad);

  const composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));
  composer.addPass(
    new UnrealBloomPass(
      new THREE.Vector2(window.innerWidth, window.innerHeight),
      1.2,
      0.55,
      0.85
    )
  );

  const clock = new THREE.Clock();
  const SCAN_CYCLE = 10.0;
  const SCAN_SWEEP = 6.0;

  function bufferedSecondsAhead(v) {
    try {
      if (!v.buffered || v.buffered.length === 0) return 0;
      const t = v.currentTime;
      let best = 0;
      for (let i = 0; i < v.buffered.length; i++) {
        const start = v.buffered.start(i);
        const end = v.buffered.end(i);
        if (t >= start && t <= end) best = Math.max(best, end - t);
      }
      return best;
    } catch {
      return 0;
    }
  }

  /** Seconds of media ahead of playhead we require before hiding the loader (avoids early choppy frames). */
  function minBufferSecondsAhead(v) {
    try {
      const d = v.duration;
      if (Number.isFinite(d) && d > 0 && d < 6) {
        return Math.max(0.55, Math.min(1.2, d * 0.42));
      }
    } catch (_) {}
    return 1.2;
  }

  let didReveal = false;
  let glWarmupFrames = 0;
  let videoFramesDecoded = 0;
  let rvfcChainStarted = false;
  /** performance.now() when we first saw steady playback (decoder + compositor warm-up). */
  let playWarmStartMs = 0;
  const hasRvfc = typeof video.requestVideoFrameCallback === "function";

  function startVideoFrameCounting() {
    if (!hasRvfc || rvfcChainStarted || didReveal) return;
    rvfcChainStarted = true;
    const step = () => {
      if (didReveal) return;
      videoFramesDecoded += 1;
      video.requestVideoFrameCallback(step);
    };
    video.requestVideoFrameCallback(step);
  }

  function revealWhenReady() {
    if (didReveal) return;
    didReveal = true;
    document.getElementById("loading")?.classList.add("hidden");
    try {
      window.webkit?.messageHandlers?.scanBackgroundReady?.postMessage("1");
    } catch (_) {}
  }

  setTimeout(() => {
    if (!didReveal) revealWhenReady();
  }, 16000);

  function animate() {
    requestAnimationFrame(animate);
    const elapsed = clock.getElapsedTime();

    const ct = elapsed % SCAN_CYCLE;
    const progress =
      ct < SCAN_SWEEP ? 1.0 - Math.pow(1.0 - ct / SCAN_SWEEP, 2) : 1.1;

    material.uniforms.uProgress.value = progress;
    material.uniforms.uTouchUv.value.copy(touchUv);
    material.uniforms.uTouchStrength.value = touchStrength;

    composer.render();

    if (!didReveal) {
      const playing = !video.paused && video.readyState >= 3;
      const t = video.currentTime;
      if (playing && t > 0.02) {
        if (!playWarmStartMs) playWarmStartMs = performance.now();
        glWarmupFrames += 1;
        startVideoFrameCounting();
      }

      const ahead = bufferedSecondsAhead(video);
      const needAhead = minBufferSecondsAhead(video);
      const bufferOk = ahead >= needAhead;
      const msSincePlayWarm = playWarmStartMs
        ? performance.now() - playWarmStartMs
        : 0;
      // Wall-clock after first frames: GPU + video decode pipeline often still stutters without this.
      const wallOk = msSincePlayWarm >= 3200;
      const decodedOk = !hasRvfc || videoFramesDecoded >= 32;
      const glOk = glWarmupFrames >= 32;

      if (
        playing &&
        t > 0.05 &&
        bufferOk &&
        wallOk &&
        glOk &&
        decodedOk
      ) {
        revealWhenReady();
      }
    }
  }
  animate();

  window.addEventListener("resize", () => {
    const w = window.innerWidth;
    const h = window.innerHeight;
    renderer.setSize(w, h);
    composer.setSize(w, h);
    updateAspectUniforms();
  });
})().catch(() => {
  document.getElementById("loading")?.classList.add("hidden");
  try {
    window.webkit?.messageHandlers?.scanBackgroundReady?.postMessage("0");
  } catch (_) {}
});
