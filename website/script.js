const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const isMobile = window.matchMedia("(max-width: 650px)").matches;
const yearEl = document.getElementById("year");
if (yearEl) yearEl.textContent = new Date().getFullYear();

// Keep the FAQ native and make opening one answer close the others.
const faqItems = [...document.querySelectorAll(".faq-item")];
faqItems.forEach((item) => item.addEventListener("toggle", () => {
  if (item.open) faqItems.forEach((other) => { if (other !== item) other.open = false; });
}));

// Header, sticky CTA, and progress strip share one lightweight scroll listener.
const header = document.querySelector(".site-header");
const progressBar = document.querySelector(".scroll-progress-bar");
const stickyDownload = document.getElementById("sticky-download");
const scrollCue = document.querySelector(".scroll-cue");
let scrollQueued = false;
function updateScrollUI() {
  const scrollY = window.scrollY;
  const scrollable = document.documentElement.scrollHeight - window.innerHeight;
  const percent = scrollable > 0 ? Math.min(1, Math.max(0, scrollY / scrollable)) : 0;
  if (progressBar) progressBar.style.transform = `scaleX(${percent})`;
  header?.classList.toggle("is-scrolled", scrollY > 20);
  const showSticky = scrollY > 480;
  stickyDownload?.classList.toggle("is-visible", showSticky);
  stickyDownload?.setAttribute("aria-hidden", String(!showSticky));
  if (scrollCue) scrollCue.style.opacity = scrollY > 45 ? "0" : "1";
  scrollQueued = false;
}
window.addEventListener("scroll", () => {
  if (scrollQueued) return;
  scrollQueued = true;
  requestAnimationFrame(updateScrollUI);
}, { passive: true });
updateScrollUI();

// Active section navigation for desktop links.
const navLinks = document.querySelectorAll(".top-links a");
const navSections = ["features", "how", "download"].map((id) => document.getElementById(id)).filter(Boolean);
if ("IntersectionObserver" in window && navSections.length) {
  const navObserver = new IntersectionObserver((entries) => entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    navLinks.forEach((link) => {
      const active = link.getAttribute("href") === `#${entry.target.id}`;
      link.classList.toggle("active", active);
      if (active) link.setAttribute("aria-current", "location"); else link.removeAttribute("aria-current");
    });
  }), { threshold: 0, rootMargin: "-35% 0px -55% 0px" });
  navSections.forEach((section) => navObserver.observe(section));
}

// Supporting copy reveals only as it approaches the viewport.
const revealTargets = document.querySelectorAll(".metric-intro, .metric, .feature-heading, .feature-panel, .proof-strip, .install-section > *, .faq-heading, .faq-item, .footer-brand, .footer-column, .footer-bottom");
if ("IntersectionObserver" in window && !reducedMotion) {
  const revealObserver = new IntersectionObserver((entries, observer) => entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    entry.target.classList.add("is-visible");
    observer.unobserve(entry.target);
  }), { threshold: .12, rootMargin: "0px 0px -7% 0px" });
  revealTargets.forEach((el) => el.classList.add("js-reveal"));
  revealTargets.forEach((el, index) => { el.style.transitionDelay = `${(index % 3) * 90}ms`; revealObserver.observe(el); });
} else revealTargets.forEach((el) => el.classList.add("is-visible"));

// Scroll-controlled Three.js route. Low geometry and a capped pixel ratio keep it light.
const canvas = document.getElementById("route-canvas");
const journey = document.querySelector(".journey");
const distanceLabel = document.getElementById("distance-label");
const distanceValue = document.getElementById("scene-distance-value");
let routeProgress = reducedMotion ? .55 : 0;
let renderer = null;
let scene = null;
let camera = null;
let vehicle = null;
let destinationRing = null;
let particleField = null;
let routeCurve = null;
let sceneFrame = 0;
let disposed = false;

function setJourneyProgress(progress) {
  if (!reducedMotion) routeProgress = Math.max(0, Math.min(1, progress));
  if (distanceLabel && distanceValue) {
    if (routeProgress < .2) { distanceLabel.textContent = "DESTINATION SET"; distanceValue.innerHTML = 'ROUTE <small>READY</small>'; }
    else if (routeProgress < .52) { distanceLabel.textContent = "FIRST ALERT"; distanceValue.innerHTML = '1.0 <small>KM</small>'; }
    else if (routeProgress < .84) { distanceLabel.textContent = "NEXT ALERT"; distanceValue.innerHTML = '300 <small>M</small>'; }
    else { distanceLabel.textContent = "ARRIVED"; distanceValue.innerHTML = 'YOU\'RE <small>HERE</small>'; }
  }
}

if (journey && window.gsap && window.ScrollTrigger) {
  gsap.registerPlugin(ScrollTrigger);
  ScrollTrigger.create({ trigger: journey, start: "top top", end: "bottom bottom", scrub: .35, onUpdate: (self) => setJourneyProgress(self.progress) });
} else if (journey) {
  const updateJourney = () => {
    const rect = journey.getBoundingClientRect();
    setJourneyProgress(Math.max(0, Math.min(1, -rect.top / Math.max(1, journey.offsetHeight - innerHeight))));
  };
  window.addEventListener("scroll", updateJourney, { passive: true });
  updateJourney();
}

function startThreeScene() {
  if (!canvas || !window.THREE || !window.THREE.WebGLRenderer) return false;
  const THREE = window.THREE;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: !isMobile, powerPreference: "low-power" });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, isMobile ? 1 : 1.5));
    renderer.setSize(canvas.clientWidth || innerWidth, canvas.clientHeight || innerHeight, false);
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    scene = new THREE.Scene();
    scene.fog = new THREE.FogExp2(0x080b12, .024);
    camera = new THREE.PerspectiveCamera(43, innerWidth / innerHeight, .1, 100);
    camera.position.set(0, 8, 15);
    const ambient = new THREE.HemisphereLight(0x8798c8, 0x090b11, 1.1);
    scene.add(ambient);
    const keyLight = new THREE.PointLight(0x566fff, 8, 24);
    keyLight.position.set(-3, 4, 2);
    scene.add(keyLight);

    const grid = new THREE.GridHelper(42, 42, 0x202532, 0x171b23);
    grid.position.y = -.24;
    grid.material.transparent = true;
    grid.material.opacity = isMobile ? .035 : .055;
    scene.add(grid);

    routeCurve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(-2.7, .02, 8), new THREE.Vector3(-2.1, .02, 5), new THREE.Vector3(-1.7, .02, 2),
      new THREE.Vector3(-.9, .02, -.5), new THREE.Vector3(.3, .02, -2.8), new THREE.Vector3(1.6, .02, -4.8),
      new THREE.Vector3(1.8, .02, -7.2), new THREE.Vector3(.7, .02, -9.4), new THREE.Vector3(-.2, .02, -12)
    ], false, "catmullrom", .45);

    const routeGeometry = new THREE.TubeGeometry(routeCurve, 180, .052, 8, false);
    const routeCore = new THREE.Mesh(routeGeometry, new THREE.MeshBasicMaterial({ color: 0x8ea3ff }));
    const routeGlow = new THREE.Mesh(new THREE.TubeGeometry(routeCurve, 120, .11, 7, false), new THREE.MeshBasicMaterial({ color: 0x536bd8, transparent: true, opacity: .09 }));
    scene.add(routeGlow, routeCore);

    const nodeMaterial = new THREE.MeshStandardMaterial({ color: 0x909bb9, emissive: 0x394d91, emissiveIntensity: .75, roughness: .4, metalness: .08 });
    [.25, .65].forEach((point, index) => {
      const node = new THREE.Mesh(new THREE.SphereGeometry(index ? .13 : .17, 16, 12), nodeMaterial);
      node.position.copy(routeCurve.getPoint(point)); node.position.y = .12; scene.add(node);
      const halo = new THREE.Mesh(new THREE.TorusGeometry(index ? .25 : .3, .009, 5, 48), new THREE.MeshBasicMaterial({ color: index ? 0x7775bb : 0x6989d9, transparent: true, opacity: .28 }));
      halo.position.copy(node.position); halo.rotation.x = Math.PI / 2; scene.add(halo);
    });

    const destination = new THREE.Mesh(new THREE.SphereGeometry(.18, 20, 16), new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0x3f5dab, emissiveIntensity: 1.5, roughness: .38 }));
    destination.position.copy(routeCurve.getPoint(1)); destination.position.y = .18; scene.add(destination);
    destinationRing = new THREE.Mesh(new THREE.TorusGeometry(.34, .012, 6, 64), new THREE.MeshBasicMaterial({ color: 0x8ea3ff, transparent: true, opacity: .52 }));
    destinationRing.position.copy(destination.position); destinationRing.rotation.x = Math.PI / 2; scene.add(destinationRing);

    vehicle = new THREE.Group();
    const shell = new THREE.Mesh(new THREE.SphereGeometry(.105, 20, 16), new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0x566fae, emissiveIntensity: .7, roughness: .3 }));
    const aura = new THREE.Mesh(new THREE.SphereGeometry(.27, 16, 12), new THREE.MeshBasicMaterial({ color: 0x728cf0, transparent: true, opacity: .1 }));
    vehicle.add(aura, shell); scene.add(vehicle);

    const count = isMobile ? 65 : 150;
    const positions = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      positions[i * 3] = (Math.random() - .5) * 27;
      positions[i * 3 + 1] = Math.random() * 7 - .2;
      positions[i * 3 + 2] = (Math.random() - .5) * 32;
    }
    const particleGeometry = new THREE.BufferGeometry();
    particleGeometry.setAttribute("position", new THREE.BufferAttribute(positions, 3));
    particleField = new THREE.Points(particleGeometry, new THREE.PointsMaterial({ color: 0x69758d, size: isMobile ? .018 : .022, transparent: true, opacity: isMobile ? .12 : .2, sizeAttenuation: true }));
    scene.add(particleField);

    const resize = () => {
      if (!renderer || !camera) return;
      const w = canvas.clientWidth || innerWidth; const h = canvas.clientHeight || innerHeight;
      renderer.setPixelRatio(Math.min(devicePixelRatio || 1, isMobile ? 1 : 1.5));
      renderer.setSize(w, h, false); camera.aspect = w / h; camera.updateProjectionMatrix();
    };
    window.addEventListener("resize", resize, { passive: true });
    const render = (time = 0) => {
      if (disposed || !renderer) return;
      if (!reducedMotion) sceneFrame = requestAnimationFrame(render);
      const t = routeProgress;
      const point = routeCurve.getPoint(Math.min(.995, Math.max(.005, t)));
      vehicle.position.copy(point); vehicle.position.y = .27 + (reducedMotion ? 0 : Math.sin(time * .0018) * .035);
      vehicle.rotation.y = Math.PI + t * .35;
      const cameraZ = 15 - Math.max(0, t - .12) * 4.6;
      camera.position.x = reducedMotion ? 0 : Math.sin(t * Math.PI * 1.2) * (isMobile ? .5 : .85);
      camera.position.y = 8.2 - Math.max(0, t - .7) * (isMobile ? 1.1 : 1.6);
      camera.position.z = cameraZ;
      camera.lookAt(point.x * .34, 0, -1.5 - t * 3.1);
      if (destinationRing && !reducedMotion) { const pulse = 1 + Math.sin(time * .002) * .12; destinationRing.scale.setScalar(t > .86 ? pulse * 1.35 : pulse); }
      if (particleField && !reducedMotion) particleField.rotation.y = time * .000025;
      renderer.render(scene, camera);
    };
    if (reducedMotion) { vehicle.position.copy(routeCurve.getPoint(.55)); vehicle.position.y = .27; }
    render();
    return true;
  } catch (error) {
    console.warn("3D route could not start; showing a lightweight route fallback.", error);
    renderer?.dispose(); renderer = null;
    return false;
  }
}

function startCanvasFallback() {
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  if (!ctx) return;
  const resize = () => { const dpr = Math.min(devicePixelRatio || 1, isMobile ? 1 : 1.5); canvas.width = innerWidth * dpr; canvas.height = innerHeight * dpr; ctx.setTransform(dpr,0,0,dpr,0,0); };
  resize(); window.addEventListener("resize", resize, { passive: true });
  const paint = () => {
    if (disposed) return;
    const w = innerWidth, h = innerHeight;
    ctx.clearRect(0,0,w,h);
    ctx.strokeStyle = "rgba(170,184,215,.035)"; ctx.lineWidth = 1;
    for(let y=h*.52;y<h;y+=52){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(w,y);ctx.stroke();}
    const route = [[w*.53,h*.87],[w*.47,h*.73],[w*.48,h*.59],[w*.54,h*.45],[w*.52,h*.3],[w*.46,h*.14]];
    ctx.beginPath(); ctx.moveTo(...route[0]); route.slice(1).forEach(p=>ctx.lineTo(...p)); ctx.strokeStyle="rgba(83,107,216,.12)";ctx.lineWidth=12;ctx.shadowBlur=22;ctx.shadowColor="#536bd8";ctx.stroke();
    ctx.beginPath();ctx.moveTo(...route[0]);route.slice(1).forEach(p=>ctx.lineTo(...p));ctx.strokeStyle="#8ea3ff";ctx.lineWidth=2;ctx.shadowBlur=5;ctx.stroke();ctx.shadowBlur=0;
    [.28,.64,1].forEach((t,i)=>{const idx=Math.round(t*(route.length-1));const p=route[idx];ctx.beginPath();ctx.arc(p[0],p[1],i===2?7:5,0,Math.PI*2);ctx.fillStyle=i===2?"#a8aaff":"#85eaff";ctx.shadowBlur=20;ctx.shadowColor=ctx.fillStyle;ctx.fill();ctx.shadowBlur=0;});
    const ix=Math.round(routeProgress*(route.length-1));const pos=route[ix];ctx.beginPath();ctx.arc(pos[0],pos[1],7,0,Math.PI*2);ctx.fillStyle="#fff";ctx.shadowBlur=24;ctx.shadowColor="#64cfff";ctx.fill();ctx.shadowBlur=0;
    if(!reducedMotion) requestAnimationFrame(paint);
  };
  paint();
}

if (!startThreeScene()) startCanvasFallback();
window.addEventListener("pagehide", () => {
  disposed = true; cancelAnimationFrame(sceneFrame);
  if (scene) scene.traverse((object) => { object.geometry?.dispose?.(); if (Array.isArray(object.material)) object.material.forEach((m) => m.dispose()); else object.material?.dispose?.(); });
  renderer?.dispose();
}, { once: true });
