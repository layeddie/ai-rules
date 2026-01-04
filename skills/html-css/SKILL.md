# HTML/CSS Best Practices

**Skill Type**: Technical Expertise
**Purpose**: Semantic HTML, accessible CSS, and progressive enhancement based on 2026 standards
**Philosophy**: Jason Knight's approach - semantic HTML first, frameworks only when needed

---

## Philosophy

### Core Principles

- **Semantic HTML First**: Build from proper markup, add layers progressively
- **Progressive Enhancement**: Core functionality works without JavaScript
- **Accessibility-First**: WCAG 2.2 AA compliance as baseline
- **Mobile-First**: Design for smallest screens, enhance upward
- **Framework Minimalism**: Use plain HTML/CSS, frameworks only when justified

### Technology Preference Order

1. **Pure HTML/CSS** (semantic, accessible)
2. **Vanilla JavaScript** (only for interactions, no frameworks)
3. **Svelte** (when component reactivity needed, accessible by default)
4. **DaisyUI** (when UI component library needed, Tailwind-free)
5. **Tailwind CSS** (last resort, fallback only)

### Inspiration

Jason Knight's approach: https://medium.com/codex/html-illiteracy-is-it-really-so-hard-part-1-of-2-e28335857bbf

---

## HTML Best Practices (2026 Standards)

### Semantic Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title</title>
</head>
<body>
  <header>
    <nav aria-label="Main Navigation">
      <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
      </ul>
    </nav>
  </header>

  <main>
    <article>
      <h1>Main Heading</h1>
      <section>
        <h2>Section Heading</h2>
        <p>Content here</p>
      </section>
    </article>
  </main>

  <aside aria-label="Sidebar">
    <h3>Related</h3>
    <nav aria-label="Related Content">
      <ul>
        <li><a href="/related1">Related 1</a></li>
        <li><a href="/related2">Related 2</a></li>
      </ul>
    </nav>
  </aside>

  <footer>
    <p>&copy; 2026 Your Site</p>
  </footer>
</body>
</html>
```

### Headings Hierarchy

- Use `<h1>` for page title (one per page)
- Use `<h2>` for major sections
- Use `<h3>` for subsections
- Never skip heading levels
- Never use headings for styling (use CSS classes)

### Forms and Accessibility

```html
<form action="/submit" method="post">
  <div>
    <label for="email">Email address</label>
    <input type="email" id="email" name="email" 
           aria-required="true"
           aria-invalid="false" />
    <span id="email-error" class="error" role="alert"></span>
  </div>

  <div>
    <label for="message">Message</label>
    <textarea id="message" name="message" 
              aria-required="true"></textarea>
  </div>

  <button type="submit">Submit</button>
</form>
```

---

## CSS Best Practices (2026 Standards)

### Modern Layouts

```css
/* Use Grid for 2D layouts */
.container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
}

/* Use Flexbox for 1D layouts */
.navbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* Mobile-first media queries */
.card {
  padding: 1rem;
}

@media (min-width: 768px) {
  .card {
    padding: 2rem;
  }
}
```

### CSS Variables (Custom Properties)

```css
:root {
  --color-primary: #3b82f6;
  --color-secondary: #64748b;
  --color-text: #1f2937;
  --spacing-unit: 0.25rem;
}

.button {
  background-color: var(--color-primary);
  color: white;
  padding: var(--spacing-unit);
}
```

### Avoid Anti-Patterns

- ❌ `!important` (use specificity)
- ❌ Inline styles (use external CSS)
- ❌ Magic numbers (use CSS variables)
- ❌ Div soup (use semantic HTML)
- ❌ Frameworks by default

---

## JavaScript Best Practices

### Progressive Enhancement

```javascript
// Feature detection
if ('serviceWorker' in navigator) {
  // Enhance with service worker
}

// Progressive enhancement
document.addEventListener('DOMContentLoaded', function() {
  // Core functionality works without JS
  if (window.fetch) {
    // Enhance with fetch API
  }
});
```

### Accessibility

```javascript
// Focus management
function trapFocus(element) {
  const focusableElements = element.querySelectorAll(
    'a, button, input, [tabindex]:not([tabindex="-1"])'
  );
  
  const firstElement = focusableElements[0];
  const lastElement = focusableElements[focusableElements.length - 1];

  firstElement.focus();

  element.addEventListener('keydown', (e) => {
    if (e.key === 'Tab' && e.shiftKey) {
      e.preventDefault();
      lastElement.focus();
    } else if (e.key === 'Tab') {
      e.preventDefault();
      firstElement.focus();
    }
  });
}

// ARIA live regions
function announceToScreenReader(message) {
  const announcement = document.createElement('div');
  announcement.setAttribute('role', 'status');
  announcement.setAttribute('aria-live', 'polite');
  announcement.textContent = message;
  
  document.body.appendChild(announcement);
  
  setTimeout(() => {
    document.body.removeChild(announcement);
  }, 1000);
}
```

### Performance

```javascript
// Lazy loading
function lazyLoadImages() {
  const images = document.querySelectorAll('img[data-src]');
  
  const imageObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target;
        img.src = img.dataset.src;
        observer.unobserve(img);
      }
    });
  });

  images.forEach(img => imageObserver.observe(img));
}

// Event delegation
document.addEventListener('click', (e) => {
  if (e.target.matches('.dynamic-content')) {
    // Handle dynamic content
  }
});
```

---

## WCAG 2.2 Compliance Checklist

### Perceivable

- [ ] Provide text alternatives for non-text content
- [ ] Provide alternatives for time-based media
- [ ] Create content that can be presented in different ways
- [ ] Make it easier for users to see and hear content

### Operable

- [ ] Make all functionality available from a keyboard
- [ ] Provide users enough time to read and use content
- [ ] Do not design content in a way that is known to cause seizures
- [ ] Provide ways to help users navigate, find content, and determine where they are

### Understandable

- [ ] Make text content readable and understandable
- [ ] Make the appearance and operation of content predictable
- [ ] Provide input assistance to help users avoid and correct mistakes

### Robust

- [ ] Maximize compatibility with current and future user agents
- [ ] Ensure content is robust and interpreted reliably

---

## LiveView Integration

### HEEx Template Guidelines

```elixir
~H"""
<div class="content-wrapper">
  <h1><%= @page_title %></h1>
  
  <section class="card-grid">
    <%= for item <- @items do %>
      <article class="card" aria-labelledby={"card-#{item.id}-title"}>
        <h2 id={"card-#{item.id}-title"}><%= item.title %></h2>
        <p><%= item.description %></p>
        <button phx-click="select_item" 
                phx-value={item.id}
                aria-label={"Select #{item.title}"}>
          Select
        </button>
      </article>
    <% end %>
  </section>
</div>
"""
```

### CSS Architecture for LiveView

```css
/* assets/css/app.css - Global styles */
:root {
  --color-primary: #3b82f6;
  --color-success: #10b981;
  --color-error: #ef4444;
  --spacing-unit: 1rem;
}

/* assets/css/components.css - LiveView components */
.card {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: var(--spacing-unit);
  transition: transform 0.2s ease;
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

/* assets/css/utilities.css - Utility classes */
.text-center { text-align: center; }
.mt-4 { margin-top: var(--spacing-unit); }
.mb-4 { margin-bottom: var(--spacing-unit); }
```

### JavaScript Hooks

```javascript
// assets/js/hooks.js - Phoenix LiveView hooks
window.addEventListener('phx:page-loading-stop', () => {
  // Page loaded, enhance progressively
  console.log('Page loaded, ready for enhancements');
});

window.addEventListener('phx:form-error', (event) => {
  // Handle form errors with focus management
  const firstError = document.querySelector('[role="alert"]');
  if (firstError) {
    firstError.focus();
  }
});
```

---

## When to Use This Skill

Invoke HTML/CSS specialist when:
- Creating or updating LiveView HEEx templates
- Designing CSS for Phoenix assets
- Implementing accessible forms and navigation
- Auditing accessibility
- Optimizing for performance
- Deciding on JavaScript vs framework

---

## Key Resources

- [Jason Knight's HTML Illiteracy Article](https://medium.com/codex/html-illiteracy-is-it-really-so-hard-part-1-of-2-e28335857bbf)
- [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web)
- [WCAG 2.2 Guidelines](https://www.w3.org/WAI/WCAG22/quickref/)
- [Inclusive Design Principles](https://www.bigdropinc.com/blog/inclusive-design-2026-accessibility-essentials-modern-websites/)
- [Tailwind vs Semantic CSS](https://nuejs.org/blog/tailwind-vs-semantic-css/)
- [HTML A11y Checklist](https://www.a11yproject.com/checklist/)

---

**Follow this skill to ensure semantic, accessible, and performant web interfaces in Elixir/BEAM projects.**

---

## Key Resources

### Phoenix Learning & Best Practices

**Phoenix Storybook**: https://github.com/phenixdigital/phoenix_storybook/fork
- Official Phoenix documentation and examples
- LiveView patterns and best practices
- Real-time features with PubSub
- Comprehensive guides for all Phoenix features

**When to Use**:
- Learning Phoenix LiveView patterns
- Understanding Phoenix framework conventions
- Finding code examples for specific features
- Troubleshooting Phoenix issues

### Ash Framework Best Practices

**Ash Igniter**: https://github.com/ash-project/igniter
- Official Ash documentation and interactive guides
- Domain modeling examples and patterns
- Query building and optimization techniques
- Resource action implementation guides

**When to Use**:
- Learning Ash resource and domain modeling
- Understanding Ash actions and changesets
- Building complex queries with Ash
- Troubleshooting Ash issues

### Elixir/BEAM Best Practices

**Elixir Guides**: https://hexdocs.pm/elixir
- Official Elixir documentation and best practices
- OTP patterns and supervision
- Concurrency and fault tolerance
- BEAM VM concepts

**When to Use**:
- Looking up Elixir functions and patterns
- Understanding OTP principles and GenServer patterns
- Learning BEAM VM concepts
- Finding examples for common tasks
