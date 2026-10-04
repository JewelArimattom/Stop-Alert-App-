# StopAlert Website

Static product website for the StopAlert Android app.

## Files

- `index.html` — product experience and download page
- `styles.css` — responsive visual design and motion
- `script.js` — route scene, scroll interactions, and page behavior
- `assets/logo.png` — StopAlert logo
- `downloads/StopAlert-v1.0.0.apk` — Android installer

## Run locally

Open `index.html` directly, or run a static server from the project root:

```bash
python -m http.server 8080
```

Then open `http://localhost:8080/website/`.

The route scene uses Three.js and GSAP from public CDNs. If WebGL is unavailable, a lightweight canvas route is shown instead.

For a new Android release, replace the APK file and update its download links in `index.html`.
