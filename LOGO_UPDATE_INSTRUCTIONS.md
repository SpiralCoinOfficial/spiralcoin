# SpiralCoin Logo Update Instructions

## Update Logo to Match Your GitHub Profile Photo

The trading platform has been updated to include a logo image that matches your GitHub profile photo. Follow these steps to complete the logo integration:

### Step 1: Get Your GitHub Username
Your GitHub profile URL is typically: `https://github.com/YOUR_USERNAME`
Replace `YOUR_USERNAME` in the URL below with your actual GitHub username.

### Step 2: Update the Logo URL
In `trading_platform.html`, find this line:
```html
<img src="https://github.com/[YOUR_GITHUB_USERNAME].png?size=80" alt="SpiralCoin Logo" onerror="this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMjAiIGZpbGw9IiNmZmNjMDAiLz4KPHRleHQgeD0iMjAiIHk9IjI1IiBmb250LWZhbWlseT0iQXJpYWwiIGZvbnQtc2l6ZT0iMTIiIGZpbGw9IiMxYTE4MmUiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkxPR088L3RleHQ+Cjwvc3ZnPg=='">
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
