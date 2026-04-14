# StopAlert Premium Website

This folder contains a static website with a direct APK download button.

## Files
- `index.html` - Landing page
- `styles.css` - Premium responsive styling
- `script.js` - Small UI interactions
- `assets/logo.png` - Website logo
- `downloads/StopAlert-Premium-v1.0.0.apk` - Installable Android APK

## Run locally
Open `index.html` directly, or run a local static server:

```bash
# from project root
python -m http.server 8080
```

Then open `http://localhost:8080/website/`.

## Free hosting options

### Option 1: Netlify (easy)
1. Create a free Netlify account.
2. Drag and drop the `website` folder in Netlify Deploy page.
3. Netlify gives you a shareable URL.

### Option 2: Cloudflare Pages (free)
1. Create a free Cloudflare account.
2. Create a Pages project and upload the `website` folder.
3. Share the generated URL.

### Option 3: GitHub Pages (free)
1. Push the `website` folder to a GitHub repository.
2. In repository settings, enable GitHub Pages.
3. Select branch/folder and publish.

## Notes
- If you build a new APK version, replace the file in `downloads/` and update filename in `index.html`.
- For Play Store publishing later, configure a release keystore in Android signing settings.
