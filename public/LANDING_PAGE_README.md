# Landing Page README

This directory contains the static assets for the SpiralCoin landing page.

## Structure

```
public/
├── index.html          # Main landing page
├── css/
│   └── styles.css     # Styling
├── js/
│   └── main.js        # JavaScript functionality
└── images/
    └── logo.png       # Brand assets
```

## Features

- Responsive design for all devices
- Modern, clean interface
- Fast loading times
- SEO optimized
- Accessible (WCAG 2.1)

## Development

To work on the landing page locally:

```bash
# Serve the public directory
npx serve . -p 3000
```

Or run the full application:

```bash
cd ..
npm start
```

## Deployment

The landing page is automatically deployed as part of the main SpiralCoin application.

## Customization

### Update Content
Edit `index.html` to modify text and structure.

### Change Styling
Edit `css/styles.css` to adjust colors, fonts, and layout.

### Add Functionality
Edit `js/main.js` to add interactive features.

## Best Practices

- Keep images optimized (< 200KB)
- Minify CSS and JS for production
- Test on multiple browsers
- Validate HTML and accessibility

## References

- [Landing Page Deployment](../LANDING_PAGE_DEPLOYMENT.md)
- [Enhancement Plans](../LANDING_PAGE_ENHANCEMENTS.md)
- [Main Documentation](../README.md)
