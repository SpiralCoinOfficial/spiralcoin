// Smooth scrolling and active nav links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Hamburger menu
const hamburger = document.querySelector('.hamburger');
const navLinks = document.querySelector('.nav-links');

if (hamburger && navLinks) {
    hamburger.addEventListener('click', () => {
        const isOpen = navLinks.classList.toggle('open');
        hamburger.classList.toggle('active', isOpen);
        hamburger.setAttribute('aria-expanded', String(isOpen));
    });
}

// Counter animation for stats
function animateCounter(element, target, duration = 2000) {
    const start = 0;
    const increment = target / (duration / 16);
    let current = 0;

    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            current = target;
            clearInterval(timer);
        }

        // Format number based on size
        if (target > 1000000) {
            element.textContent = Math.floor(current).toLocaleString();
        } else if (target > 1000) {
            element.textContent = Math.floor(current).toLocaleString();
        } else {
            element.textContent = current.toFixed(1);
        }
    }, 16);
}

// Trigger counter animations when section is in view
const observerOptions = {
    threshold: 0.5
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const numbers = entry.target.querySelectorAll('[data-target]');
            numbers.forEach(num => {
                const target = parseFloat(num.getAttribute('data-target'));
                animateCounter(num, target);
            });
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe hero stats and stats sections
const heroStats = document.querySelector('.hero-stats');
const statsGrid = document.querySelector('.stats-grid');

if (heroStats) observer.observe(heroStats);
if (statsGrid) observer.observe(statsGrid);

// Navbar styling on scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.boxShadow = '0 2px 20px rgba(0,0,0,0.3)';
    } else {
        navbar.style.boxShadow = 'none';
    }
});

// Active nav link highlighting
window.addEventListener('scroll', () => {
    const navLinks = document.querySelectorAll('.nav-link');
    let current = '';

    const sections = document.querySelectorAll('section');
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        if (scrollY >= sectionTop - 200) {
            current = section.getAttribute('id');
        }
    });

    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href').slice(1) === current) {
            link.classList.add('active');
        }
    });
});

// Add ripple effect to buttons
document.querySelectorAll('.btn').forEach(button => {
    button.addEventListener('click', function (e) {
        const ripple = document.createElement('span');
        const rect = this.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = e.clientX - rect.left - size / 2;
        const y = e.clientY - rect.top - size / 2;

        ripple.style.width = ripple.style.height = size + 'px';
        ripple.style.left = x + 'px';
        ripple.style.top = y + 'px';
        ripple.classList.add('ripple');

        this.appendChild(ripple);

        setTimeout(() => ripple.remove(), 600);
    });
});

// Add ripple animation styles
const style = document.createElement('style');
style.textContent = `
    .btn {
        position: relative;
        overflow: hidden;
    }

    .ripple {
        position: absolute;
        border-radius: 50%;
        background: rgba(255, 255, 255, 0.7);
        transform: scale(0);
        animation: ripple-animation 0.6s ease-out;
        pointer-events: none;
    }

    @keyframes ripple-animation {
        to {
            transform: scale(4);
            opacity: 0;
        }
    }

    .nav-link.active {
        color: #ffcc00;
        text-shadow: 0 0 10px rgba(255, 204, 0, 0.5);
    }
`;
document.head.appendChild(style);

// Lazy load images
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                observer.unobserve(img);
            }
        });
    });

    document.querySelectorAll('img.lazy').forEach(img => imageObserver.observe(img));
}

// Mobile menu close on link click
document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
        if (navLinks && hamburger) {
            navLinks.classList.remove('open');
            hamburger.classList.remove('active');
            hamburger.setAttribute('aria-expanded', 'false');
        }
    });
});

// Parallax effect for hero section
window.addEventListener('scroll', () => {
    const hero = document.querySelector('.hero');
    if (hero) {
        const scrollPosition = window.scrollY;
        hero.style.backgroundPosition = `center ${scrollPosition * 0.5}px`;
    }
});

// Toast notification helper
function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: ${type === 'success' ? '#00ff88' : '#ff4444'};
        color: #000;
        padding: 1rem 2rem;
        border-radius: 8px;
        z-index: 2000;
        animation: slideIn 0.3s ease-out;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease-out';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Add slide animations
const slideStyles = document.createElement('style');
slideStyles.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }

    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(slideStyles);

// Button click handlers
document.addEventListener('DOMContentLoaded', () => {
    const primaryButtons = document.querySelectorAll('.btn-primary');
    const secondaryButtons = document.querySelectorAll('.btn-secondary');

    primaryButtons.forEach(btn => {
        if (btn.textContent.includes('Get Started') || btn.textContent.includes('Launch') || btn.textContent.includes('Start Trading')) {
            btn.addEventListener('click', () => {
                showNotification('Redirecting to trading platform...', 'success');
                setTimeout(() => window.location.href = '/trading_platform.html', 600);
            });
        }
    });

    secondaryButtons.forEach(btn => {
        if (btn.textContent.includes('Join')) {
            btn.addEventListener('click', () => {
                showNotification('Opening community link...', 'success');
                // Add your community links here
            });
        }
    });
});

// Scroll to top button
const scrollTopButton = document.createElement('button');
scrollTopButton.innerHTML = '↑';
scrollTopButton.style.cssText = `
    position: fixed;
    bottom: 2rem;
    right: 2rem;
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: linear-gradient(135deg, #ffcc00, #ffd700);
    color: #000;
    border: none;
    cursor: pointer;
    font-size: 1.5rem;
    font-weight: bold;
    display: none;
    z-index: 999;
    box-shadow: 0 4px 15px rgba(255, 204, 0, 0.3);
    transition: all 0.3s ease;
`;

document.body.appendChild(scrollTopButton);

window.addEventListener('scroll', () => {
    if (window.scrollY > 300) {
        scrollTopButton.style.display = 'flex';
        scrollTopButton.style.alignItems = 'center';
        scrollTopButton.style.justifyContent = 'center';
    } else {
        scrollTopButton.style.display = 'none';
    }
});

scrollTopButton.addEventListener('click', () => {
    window.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
});

scrollTopButton.addEventListener('mouseenter', () => {
    scrollTopButton.style.transform = 'scale(1.1)';
    scrollTopButton.style.boxShadow = '0 6px 20px rgba(255, 204, 0, 0.5)';
});

scrollTopButton.addEventListener('mouseleave', () => {
    scrollTopButton.style.transform = 'scale(1)';
    scrollTopButton.style.boxShadow = '0 4px 15px rgba(255, 204, 0, 0.3)';
});

// Performance monitoring
if ('PerformanceObserver' in window) {
    try {
        const perfObserver = new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            entries.forEach((entry) => {
                console.log('Performance:', entry.name, entry.duration);
            });
        });

        perfObserver.observe({ entryTypes: ['measure', 'navigation'] });
    } catch (e) {
        // Performance observer not supported
    }
}

console.log('SpiralCoin Landing Page loaded successfully!');

// Register Service Worker for PWA/offline support
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/service-worker.js').catch(() => {});
    });
}
