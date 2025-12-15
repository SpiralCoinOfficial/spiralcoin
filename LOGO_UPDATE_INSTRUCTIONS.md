# SpiralCoin Logo Update Instructions

## Update Logo

The trading platform now ships with a bundled logo (`public/assets/SpiralCoin_logo.png`) and still supports pulling your GitHub profile photo if you prefer. Follow these steps to complete the logo integration:

### Option A: Use the bundled SpiralCoin logo (no action needed)
`trading_platform.html` already points to `public/assets/SpiralCoin_logo.png` with correct sizing. Nothing to change if you want to keep the shipped logo.

### Option B: Match your GitHub profile photo
1) Get your GitHub username (profile URL looks like `https://github.com/YOUR_USERNAME`).
2) Replace `[YOUR_GITHUB_USERNAME]` in the `onerror` fallback URL below with your username if you want your avatar as the fallback.

### Step 2: Update the Logo URL
In `trading_platform.html`, find this line:
```html
<img src="public/assets/SpiralCoin_logo.png" srcset="public/assets/SpiralCoin_logo.png 1x, public/assets/SpiralCoin_logo.png 2x" sizes="40px" width="40" height="40" alt="SpiralCoin Logo" decoding="async" fetchpriority="high" onerror="this.src='https://github.com/[SpiralCoin].png?size=80'">
```

Replace `[YOUR_GITHUB_USERNAME]` with your actual GitHub username. For example, if your GitHub username is "johndoe", it should become:
```html
<img src="https://github.com/johndoe.png?size=80" alt="SpiralCoin Logo" onerror="this.src='data:image/svg+xml;base64,...">
```

### Step 3: Alternative - Use Custom Logo Image
If you prefer to use a different logo image:

1. **Upload your logo** to a hosting service (Imgur, GitHub repo, or your web server)
2. **Replace the src URL** with your logo's URL
3. **Adjust dimensions** if needed (currently 40x40px)

Example:
```html
<img src="https://your-domain.com/logo.png" alt="SpiralCoin Logo" onerror="this.src='fallback-logo.png'">
```

### Step 4: Test the Logo
1. Open `trading_platform.html` in a web browser
2. Check that your profile photo appears in the header
3. Verify the circular border and glow effects look good

### Logo Features
- **Circular border** with golden SpiralCoin theme colors
- **Glow effect** that matches the site's design
- **Fallback image** if the profile photo fails to load
- **Responsive sizing** that works on all devices

### Troubleshooting
- If the image doesn't load, check that your GitHub profile is public
- The `?size=80` parameter ensures good quality
- The `onerror` attribute provides a fallback "LOGO" text image

Once updated, your SpiralCoin trading platform will display your personal logo, creating a unique brand identity that matches your GitHub presence!
