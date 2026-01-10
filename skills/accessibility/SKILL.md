# Accessibility (a11y) Skill

## Overview

Comprehensive guide to building accessible web applications following WCAG 2.2 AA standards.

## When to Apply Accessibility

**Always apply accessibility** when:
- Building any user-facing interface
- Creating forms or input controls
- Implementing navigation or menus
- Displaying images, videos, or audio content
- Providing error messages or notifications

**Never skip accessibility** for:
- Internal tools (still benefit a11y)
- Mobile-only interfaces (assistive tech works on mobile)
- Complex dashboards (need more a11y, not less)
- Temporary features (bad habits persist)

## Semantic HTML

### DO: Use Semantic Elements

```html
<!-- Good: Semantic HTML -->
<header>
  <nav aria-label="Main navigation">
    <ul>
      <li><a href="/">Home</a></li>
      <li><a href="/about">About</a></li>
      <li><a href="/contact">Contact</a></li>
    </ul>
  </nav>
</header>

<main>
  <article>
    <h1>Article Title</h1>
    <p>Article content...</p>
  </article>

  <aside>
    <h2>Related Articles</h2>
    <ul>
      <li><a href="/article/1">Related Article 1</a></li>
      <li><a href="/article/2">Related Article 2</a></li>
    </ul>
  </aside>
</main>

<footer>
  <p>© 2026 MyApp</p>
</footer>
```

### DON'T: Use Div Soup

```html
<!-- Bad: Non-semantic divs -->
<div class="header">
  <div class="nav">
    <div class="nav-item"><a href="/">Home</a></div>
    <div class="nav-item"><a href="/about">About</a></div>
    <div class="nav-item"><a href="/contact">Contact</a></div>
  </div>
</div>

<div class="content">
  <div class="article">
    <div class="title">Article Title</div>
    <div class="text">Article content...</div>
  </div>
</div>
```

## ARIA Labels

### DO: Use ARIA Labels for Clarification

```html
<!-- Good: ARIA labels for context -->
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
  </ul>
</nav>

<button aria-label="Close dialog">
  <span aria-hidden="true">×</span>
</button>

<input
  type="search"
  id="search"
  aria-label="Search articles"
  placeholder="Search..."
/>

<div role="status" aria-live="polite" aria-atomic="true">
  <p id="status-message">Saved successfully</p>
</div>
```

### DON'T: Overuse ARIA

```html
<!-- Bad: Redundant ARIA -->
<nav role="navigation" aria-label="Main navigation">
  <ul>
    <li role="listitem"><a href="/" role="link">Home</a></li>
  </ul>
</nav>

<!-- Good: Semantic HTML implies roles -->
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/">Home</a></li>
  </ul>
</nav>
```

## Keyboard Navigation

### DO: Ensure Full Keyboard Navigation

```html
<!-- Good: Keyboard accessible menu -->
<nav aria-label="Main navigation">
  <button
    id="menu-button"
    aria-expanded="false"
    aria-controls="menu"
  >
    Menu
  </button>

  <ul id="menu" role="menu" aria-hidden="true">
    <li role="none">
      <a href="/" role="menuitem">Home</a>
    </li>
    <li role="none">
      <a href="/about" role="menuitem">About</a>
    </li>
  </ul>
</nav>

<script>
  const menuButton = document.getElementById('menu-button');
  const menu = document.getElementById('menu');

  menuButton.addEventListener('click', () => {
    const isExpanded = menuButton.getAttribute('aria-expanded') === 'true';
    menuButton.setAttribute('aria-expanded', !isExpanded);
    menu.setAttribute('aria-hidden', isExpanded);
  });

  // Close menu on Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      menuButton.setAttribute('aria-expanded', 'false');
      menu.setAttribute('aria-hidden', 'true');
    }
  });
</script>
```

### DON'T: Ignore Keyboard Users

```html
<!-- Bad: Click-only menu -->
<div class="menu" onclick="toggleMenu()">
  <div class="menu-item">Home</div>
  <div class="menu-item">About</div>
</div>
```

## Forms Accessibility

### DO: Use Proper Form Labels

```html
<!-- Good: Explicit labels -->
<form>
  <label for="email">
    Email address
    <input
      type="email"
      id="email"
      name="email"
      required
      aria-describedby="email-hint"
    />
    <small id="email-hint">We'll never share your email</small>
  </label>

  <fieldset>
    <legend>Subscribe to newsletter?</legend>
    <label>
      <input type="radio" name="subscribe" value="yes" />
      Yes
    </label>
    <label>
      <input type="radio" name="subscribe" value="no" />
      No
    </label>
  </fieldset>

  <button type="submit">Subscribe</button>
</form>
```

### DON'T: Use Placeholder as Label

```html
<!-- Bad: No visible label -->
<form>
  <input
    type="email"
    name="email"
    placeholder="Enter your email"
  />
  <button type="submit">Submit</button>
</form>
```

## Error Messages

### DO: Provide Clear Error Messages

```html
<!-- Good: Associated error messages -->
<form>
  <label for="email">
    Email address
    <input
      type="email"
      id="email"
      name="email"
      required
      aria-invalid="false"
      aria-describedby="email-error"
    />
  </label>

  <p id="email-error" role="alert" aria-live="assertive">
    Please enter a valid email address
  </p>
</form>
```

### DON'T: Use Color Alone for Errors

```html
<!-- Bad: Red border only -->
<input type="text" style="border: 2px solid red" />

<!-- Good: Red border + error message -->
<input
  type="text"
  style="border: 2px solid red"
  aria-invalid="true"
  aria-describedby="error-message"
/>
<p id="error-message" role="alert">Invalid input</p>
```

## Focus Management

### DO: Manage Focus for Dynamic Content

```html
<!-- Good: Focus management for modals -->
<div id="modal" role="dialog" aria-labelledby="modal-title" aria-hidden="true">
  <h2 id="modal-title">Modal Title</h2>
  <p>Modal content...</p>
  <button id="close-modal">Close</button>
</div>

<button id="open-modal">Open Modal</button>

<script>
  const modal = document.getElementById('modal');
  const openButton = document.getElementById('open-modal');
  const closeButton = document.getElementById('close-modal');
  let lastFocusedElement;

  function openModal() {
    lastFocusedElement = document.activeElement;
    modal.setAttribute('aria-hidden', 'false');
    closeButton.focus();
  }

  function closeModal() {
    modal.setAttribute('aria-hidden', 'true');
    lastFocusedElement.focus();
  }

  openButton.addEventListener('click', openModal);
  closeButton.addEventListener('click', closeModal);

  // Trap focus in modal
  modal.addEventListener('keydown', (e) => {
    if (e.key === 'Tab') {
      const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    }
  });
</script>
```

## Skip Links

### DO: Provide Skip to Content Link

```html
<!-- Good: Skip link -->
<body>
  <a href="#main-content" class="skip-link">
    Skip to main content
  </a>

  <header>...</header>

  <main id="main-content">
    <h1>Main Content</h1>
    <p>...</p>
  </main>

  <style>
    .skip-link {
      position: absolute;
      top: -40px;
      left: 0;
      background: #000;
      color: #fff;
      padding: 8px;
      text-decoration: none;
      z-index: 100;
    }

    .skip-link:focus {
      top: 0;
    }
  </style>
</body>
```

## Color Contrast

### DO: Ensure Sufficient Color Contrast

```css
/* Good: Sufficient contrast */
.text-dark {
  color: #333333;  /* WCAG AA compliant with white background */
  background: #ffffff;
}

.text-light {
  color: #ffffff;  /* WCAG AA compliant with dark background */
  background: #000000;
}

.link {
  color: #0066cc;  /* WCAG AA compliant link color */
}

.link:hover {
  color: #0044aa;  /* Even better contrast on hover */
}
```

### DON'T: Use Low Contrast Colors

```css
/* Bad: Low contrast */
.text {
  color: #cccccc;  /* Not WCAG AA compliant */
  background: #ffffff;
}

.link {
  color: #99ccff;  /* Not WCAG AA compliant */
}
```

## Testing Accessibility

### DO: Test with Assistive Technology

```bash
# Automated testing tools

# Lighthouse (built into Chrome DevTools)
npm install -g lighthouse
lighthouse https://example.com --view

# axe DevTools (browser extension)
# https://www.deque.com/axe/

# Pa11y (command line)
npm install -g pa11y
pa11y https://example.com

# Screen readers for manual testing

# NVDA (Windows, free)
# https://www.nvaccess.org/

# JAWS (Windows, paid)
# https://www.freedomscientific.com/products/software/jaws/

# VoiceOver (macOS, built-in)
# Command + F5 to start

# Keyboard navigation testing

# Tab through interface
# Ensure focus indicator is visible
# Test all interactive elements
```

## Common Pitfalls

### DON'T: Ignore Accessibility

```html
<!-- Bad: Inaccessible carousel -->
<div class="carousel">
  <div class="slide">Slide 1</div>
  <div class="slide">Slide 2</div>
  <div class="slide">Slide 3</div>
</div>

<script>
  // Auto-advances without user control
  setInterval(() => {
    nextSlide();
  }, 3000);
</script>

<!-- Good: Accessible carousel -->
<div
  class="carousel"
  role="region"
  aria-label="Featured articles"
  aria-roledescription="carousel"
>
  <div class="slide" aria-hidden="false" role="group" aria-label="1 of 3">
    <h2>Slide 1</h2>
  </div>
  <div class="slide" aria-hidden="true" role="group" aria-label="2 of 3">
    <h2>Slide 2</h2>
  </div>
  <div class="slide" aria-hidden="true" role="group" aria-label="3 of 3">
    <h2>Slide 3</h2>
  </div>

  <button aria-label="Previous slide" id="prev-slide">
    <span aria-hidden="true">←</span>
  </button>
  <button aria-label="Next slide" id="next-slide">
    <span aria-hidden="true">→</span>
  </button>

  <button aria-label="Pause carousel" id="pause-carousel">
    Pause
  </button>
</div>
```

## Related Skills

- [HTML/CSS](../html-css/SKILL.md) - HTML/CSS best practices

## Related Patterns

- [Phoenix Controllers](../phoenix_controllers.md) - A11y in Phoenix
- [LiveView Patterns](../liveview.md) - LiveView a11y patterns
