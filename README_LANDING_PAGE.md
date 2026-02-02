# SpiralCoin Landing Page

This is the main landing page for the SpiralCoin cryptocurrency project.

## Overview

The landing page provides visitors with:
- Project introduction and mission
- Key features and benefits
- Technology overview
- Getting started guide
- Links to documentation and resources

## Structure

### Sections

1. **Hero Section**
   - Project logo and tagline
   - Call-to-action buttons
   - Key statistics

2. **Features**
   - Full blockchain node
   - EVM compatibility
   - Mining engine
   - Wallet management
   - Market data integration

3. **Technology Stack**
   - C++ daemon
   - Node.js API server
   - WebSocket market feed
   - Docker support

4. **Getting Started**
   - Installation instructions
   - Quick start guide
   - Links to documentation

5. **Community**
   - Social media links
   - GitHub repository
   - Developer resources

6. **Footer**
   - Navigation links
   - Legal information
   - Contact details

## Files

- `index.html` - Main landing page
- `css/styles.css` - Styling
- `js/main.js` - Interactive features
- `images/` - Assets and graphics

## Development

### Local Setup
```bash
# Serve the landing page locally
npx serve public -p 3000

# Or use the main server
npm start
```

### Editing
The landing page files are located in the `public/` directory:
- Edit HTML: `public/index.html`
- Edit styles: `public/css/styles.css`
- Edit scripts: `public/js/main.js`

## Deployment

The landing page is served as part of the main application on port 3000 (or configured port).

### Production
```bash
# Using Docker
docker-compose up -d

# Using Node.js directly
npm start
```

## Customization

### Branding
- Update logo: Replace `public/images/logo.png`
- Change colors: Edit CSS variables in `styles.css`
- Modify content: Edit `index.html`

### Analytics
Add tracking code to `index.html`:
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
```

## Performance

### Optimization
- Images are compressed and optimized
- CSS and JS are minified in production
- CDN integration for static assets
- Caching headers configured

### Metrics
- Lighthouse score target: 90+
- First Contentful Paint: < 2s
- Time to Interactive: < 3s

## SEO

### Meta Tags
Properly configured for:
- Search engines
- Social media sharing
- Open Graph protocol
- Twitter Cards

### Sitemap
Located at `/sitemap.xml` for search engine indexing.

## Accessibility

The landing page follows WCAG 2.1 guidelines:
- Semantic HTML
- Proper heading structure
- Alt text for images
- Keyboard navigation support
- Screen reader friendly

## Browser Support

Tested and supported on:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Contributing

To contribute to the landing page:
1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## References

- [Main Documentation](../README.md)
- [Deployment Guide](../LANDING_PAGE_DEPLOYMENT.md)
- [Enhancement Plans](../LANDING_PAGE_ENHANCEMENTS.md)
