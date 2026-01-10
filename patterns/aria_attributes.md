# ARIA Attributes Patterns

## Overview

Patterns for using ARIA (Accessible Rich Internet Applications) attributes to improve accessibility.

## Role Attributes

### DO: Use Semantic HTML First

```html
<!-- Good: Semantic HTML (implicit roles) -->
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
  </ul>
</nav>

<main aria-label="Main content">
  <article>
    <h1>Article Title</h1>
    <p>Article content...</p>
  </article>
</main>

<aside aria-label="Sidebar">
  <h2>Related Articles</h2>
  <ul>
    <li><a href="/article/1">Related Article</a></li>
  </ul>
</aside>

<footer aria-label="Site footer">
  <p>© 2026 MyApp</p>
</footer>
```

### DON'T: Overuse ARIA Roles

```html
<!-- Bad: Redundant ARIA roles -->
<nav role="navigation">
  <ul>
    <li><a href="/" role="link">Home</a></li>
  </ul>
</nav>

<main role="main">
  <h1 role="heading">Main Content</h1>
</main>

<footer role="contentinfo">
  <p>© 2026 MyApp</p>
</footer>
```

## Landmark Roles

### DO: Use Landmark Roles for Navigation

```html
<!-- Good: Clear landmark structure -->
<body>
  <header>
    <nav aria-label="Main navigation">
      <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
      </ul>
    </nav>
  </header>

  <main aria-label="Main content">
    <article>
      <h1>Article Title</h1>
    </article>
  </main>

  <aside aria-label="Related content">
    <h2>Related Articles</h2>
    <ul>
      <li><a href="/article/1">Related</a></li>
    </ul>
  </aside>

  <footer aria-label="Footer">
    <p>© 2026 MyApp</p>
  </footer>
</body>
```

## Interactive Element Roles

### Button Roles

```html
<!-- Good: Use button element -->
<button onclick="handleClick()">Click me</button>

<!-- Use button role for div if necessary -->
<div
  role="button"
  tabindex="0"
  onclick="handleClick()"
  onkeydown="if(event.key === 'Enter' || event.key === ' ') { handleClick() }}"
>
  Click me
</div>

<!-- ARIA pressed state for toggle buttons -->
<button
  aria-pressed="false"
  onclick="toggleButton(this)"
>
  Mute
</button>
```

### Checkbox Roles

```html
<!-- Good: Use checkbox input -->
<label>
  <input type="checkbox" id="subscribe" />
  Subscribe to newsletter
</label>

<!-- Use checkbox role for custom checkbox -->
<div
  role="checkbox"
  aria-checked="false"
  tabindex="0"
  onclick="toggleCheckbox(this)"
>
  <span aria-hidden="true">☐</span>
  Subscribe to newsletter
</div>
```

## Live Regions

### Status Messages

```html
<!-- Good: Live region for status updates -->
<div
  role="status"
  aria-live="polite"
  aria-atomic="true"
  id="status-message"
>
  <!-- Content is announced when changed -->
</div>

<button onclick="saveForm()">Save</button>

<script>
  function saveForm() {
    // Update status after save
    const status = document.getElementById('status-message');
    status.textContent = 'Saved successfully';
  }
</script>
```

### Alert Messages

```html
<!-- Good: Alert for critical messages -->
<div
  role="alert"
  id="error-message"
  aria-live="assertive"
>
  Error: Invalid email format
</div>

<input type="email" id="email" aria-describedby="error-message" />
```

### Live Chat

```html
<!-- Good: Live region for chat messages -->
<div
  role="log"
  aria-live="polite"
  aria-atomic="false"
  id="chat-messages"
>
  <div role="listitem">User1: Hello</div>
  <div role="listitem">User2: Hi there!</div>
</div>

<form onsubmit="sendMessage()">
  <label for="chat-input">Message</label>
  <input type="text" id="chat-input" aria-describedby="chat-messages" />
  <button type="submit">Send</button>
</form>
```

## Description Labels

### aria-label

```html
<!-- Good: ARIA label for context -->
<button aria-label="Close dialog">
  <span aria-hidden="true">×</span>
</button>

<nav aria-label="Main navigation">
  <ul>
    <li><a href="/">Home</a></li>
  </ul>
</nav>

<input
  type="search"
  id="search"
  aria-label="Search articles"
/>
```

### aria-labelledby

```html
<!-- Good: ARIA labelledby for form controls -->
<fieldset>
  <legend id="payment-method">Payment Method</legend>

  <input
    type="radio"
    id="credit-card"
    name="payment"
    aria-labelledby="payment-method payment-label"
  />
  <label for="credit-card" id="payment-label">Credit Card</label>

  <input
    type="radio"
    id="paypal"
    name="payment"
    aria-labelledby="payment-method paypal-label"
  />
  <label for="paypal" id="paypal-label">PayPal</label>
</fieldset>
```

### aria-describedby

```html
<!-- Good: ARIA describedby for help text -->
<label for="password">
  Password
  <input
    type="password"
    id="password"
    aria-describedby="password-hint password-strength"
  />
  <p id="password-hint">Must be at least 8 characters</p>
  <p id="password-strength">Password strength: Strong</p>
</label>
```

## State Attributes

### aria-expanded

```html
<!-- Good: ARIA expanded for accordions -->
<button
  aria-expanded="false"
  aria-controls="faq-section-1"
  onclick="toggleAccordion(this)"
>
  FAQ Question 1
</button>

<div
  id="faq-section-1"
  role="region"
  aria-hidden="true"
>
  <p>FAQ Answer 1</p>
</div>

<script>
  function toggleAccordion(button) {
    const isExpanded = button.getAttribute('aria-expanded') === 'true';
    const sectionId = button.getAttribute('aria-controls');
    const section = document.getElementById(sectionId);

    button.setAttribute('aria-expanded', !isExpanded);
    section.setAttribute('aria-hidden', isExpanded);
  }
</script>
```

### aria-selected

```html
<!-- Good: ARIA selected for tabs -->
<div role="tablist" aria-label="Content tabs">
  <button
    role="tab"
    aria-selected="true"
    aria-controls="tab-panel-1"
    onclick="selectTab(this)"
  >
    Tab 1
  </button>

  <button
    role="tab"
    aria-selected="false"
    aria-controls="tab-panel-2"
    onclick="selectTab(this)"
  >
    Tab 2
  </button>
</div>

<div
  id="tab-panel-1"
  role="tabpanel"
  aria-labelledby="tab-1"
>
  Tab 1 Content
</div>

<div
  id="tab-panel-2"
  role="tabpanel"
  aria-labelledby="tab-2"
  aria-hidden="true"
>
  Tab 2 Content
</div>
```

### aria-pressed

```html
<!-- Good: ARIA pressed for toggle buttons -->
<button
  aria-pressed="false"
  onclick="toggleButton(this)"
>
  Mute
</button>

<button
  aria-pressed="true"
  onclick="toggleButton(this)"
>
  Mute
</button>

<script>
  function toggleButton(button) {
    const isPressed = button.getAttribute('aria-pressed') === 'true';
    button.setAttribute('aria-pressed', !isPressed);
  }
</script>
```

## Accessibility Testing

### ARIA Validation

```bash
# Use axe DevTools browser extension
# https://www.deque.com/axe/

# Use Lighthouse for automated testing
npx lighthouse https://example.com --view

# Use pa11y for CI/CD
npx pa11y https://example.com
```

## Related Skills

- [Accessibility](../skills/accessibility/SKILL.md) - Comprehensive a11y guide

## Related Patterns

- [HTML/CSS](../html-css/SKILL.md) - Semantic HTML patterns
- [Keyboard Navigation](../keyboard_navigation.md) - Keyboard a11y patterns
