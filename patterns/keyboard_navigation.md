# Keyboard Navigation Patterns

## Overview

Patterns for ensuring keyboard accessibility in web applications.

## Focus Management

### Visible Focus Indicator

```css
/* Good: Clear focus indicator */
:focus-visible {
  outline: 3px solid #0066cc;
  outline-offset: 2px;
}

/* Alternative: Box shadow */
:focus {
  box-shadow: 0 0 0 3px #0066cc;
}

/* Remove default if using custom indicator */
button:focus {
  outline: none;
}

/* High contrast focus indicator for better visibility */
:focus {
  outline: 3px solid #000000;
  outline-offset: 2px;
  background: #ffff00;
  color: #000000;
}
```

### Focus Order

```html
<!-- Good: Logical focus order -->
<form>
  <!-- Focus flows in DOM order -->
  <label for="name">Name</label>
  <input type="text" id="name" />

  <label for="email">Email</label>
  <input type="email" id="email" />

  <button type="submit">Submit</button>
</form>
```

### Skip Navigation Links

```html
<!-- Good: Skip to content -->
<body>
  <a href="#main-content" class="skip-link">
    Skip to main content
  </a>

  <header>...</header>

  <main id="main-content">
    <h1>Main Content</h1>
  </main>

  <style>
    .skip-link {
      position: absolute;
      top: -40px;
      left: 0;
      background: #000;
      color: #fff;
      padding: 8px;
      z-index: 100;
    }

    .skip-link:focus {
      top: 0;
    }
  </style>
</body>
```

## Modal Focus

### Focus Trap

```html
<!-- Good: Focus trap for modals -->
<div id="modal" role="dialog" aria-labelledby="modal-title" aria-hidden="true">
  <h2 id="modal-title">Modal Title</h2>
  <p>Modal content...</p>
  <button id="modal-close">Close</button>
</div>

<button id="open-modal">Open Modal</button>

<script>
  const modal = document.getElementById('modal');
  const openButton = document.getElementById('open-modal');
  const closeButton = document.getElementById('modal-close');
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
      const focusableElements = modal.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    } else if (e.key === 'Escape') {
      closeModal();
    }
  });
</script>
```

### Focus Restoration

```html
<!-- Good: Restore focus after closing modal -->
<div id="modal" role="dialog" aria-labelledby="modal-title" aria-hidden="true">
  <h2 id="modal-title">Modal Title</h2>
  <button id="modal-close">Close</button>
</div>

<button id="open-modal">Open Modal</button>

<script>
  const modal = document.getElementById('modal');
  const openButton = document.getElementById('open-modal');
  const closeButton = document.getElementById('modal-close');
  let lastFocusedElement;

  function openModal() {
    // Save current focused element
    lastFocusedElement = document.activeElement;

    modal.setAttribute('aria-hidden', 'false');
    closeButton.focus();
  }

  function closeModal() {
    modal.setAttribute('aria-hidden', 'true');

    // Restore focus to element that opened modal
    if (lastFocusedElement) {
      lastFocusedElement.focus();
    }
  }

  openButton.addEventListener('click', openModal);
  closeButton.addEventListener('click', closeModal);
</script>
```

## Keyboard Shortcuts

### Keyboard Accessible Controls

```html
<!-- Good: Keyboard accessible dropdown -->
<button
  id="dropdown-button"
  aria-expanded="false"
  aria-haspopup="true"
>
  Dropdown
  <span aria-hidden="true">▼</span>
</button>

<ul
  id="dropdown-menu"
  role="menu"
  aria-labelledby="dropdown-button"
  aria-hidden="true"
>
  <li role="none">
    <a href="/option1" role="menuitem">Option 1</a>
  </li>
  <li role="none">
    <a href="/option2" role="menuitem">Option 2</a>
  </li>
</ul>

<script>
  const dropdownButton = document.getElementById('dropdown-button');
  const dropdownMenu = document.getElementById('dropdown-menu');
  let isOpen = false;

  function toggleDropdown() {
    isOpen = !isOpen;
    dropdownButton.setAttribute('aria-expanded', isOpen);
    dropdownMenu.setAttribute('aria-hidden', !isOpen);

    if (isOpen) {
      // Focus first menu item
      dropdownMenu.querySelector('a').focus();
    }
  }

  dropdownButton.addEventListener('click', toggleDropdown);

  // Keyboard navigation
  dropdownButton.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      toggleDropdown();
    } else if (e.key === 'Escape' && isOpen) {
      toggleDropdown();
      dropdownButton.focus();
    }
  });

  dropdownMenu.addEventListener('keydown', (e) => {
    const menuItems = Array.from(dropdownMenu.querySelectorAll('a'));
    const currentIndex = menuItems.indexOf(document.activeElement);

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      const nextIndex = (currentIndex + 1) % menuItems.length;
      menuItems[nextIndex].focus();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      const prevIndex = currentIndex - 1 < 0 ? menuItems.length - 1 : currentIndex - 1;
      menuItems[prevIndex].focus();
    } else if (e.key === 'Escape') {
      toggleDropdown();
      dropdownButton.focus();
    } else if (e.key === 'Home') {
      e.preventDefault();
      menuItems[0].focus();
    } else if (e.key === 'End') {
      e.preventDefault();
      menuItems[menuItems.length - 1].focus();
    }
  });
</script>
```

## Tab Navigation

### Proper Tab Index

```html
<!-- Good: Logical tab order -->
<form>
  <label for="field1">Field 1</label>
  <input type="text" id="field1" />

  <label for="field2">Field 2</label>
  <input type="text" id="field2" />

  <button type="submit">Submit</button>
</form>
```

### Custom Tab Index

```html
<!-- Good: Custom tab order when necessary -->
<div>
  <button tabindex="1">Button 1</button>
  <button tabindex="2">Button 2</button>
  <button tabindex="3">Button 3</button>
</div>

<!-- Better: Use semantic HTML order -->
<form>
  <label for="field1">Field 1</label>
  <input type="text" id="field1" />

  <label for="field2">Field 2</label>
  <input type="text" id="field2" />

  <button type="submit">Submit</button>
</form>
```

## Focusable Elements

### All Interactive Elements Focusable

```html
<!-- Good: Ensure all interactive elements are focusable -->
<a href="/page">Link</a>
<button>Button</button>
<input type="text" />
<select>
  <option>Option 1</option>
</select>
<textarea>Textarea</textarea>

<!-- Custom elements need tabindex -->
<div
  role="button"
  tabindex="0"
  onclick="handleClick()"
  onkeydown="if(event.key === 'Enter' || event.key === ' ') { handleClick() }}"
>
  Custom Button
</div>
```

### Hidden Focusable Elements

```html
<!-- Good: Hide decorative elements from keyboard -->
<span aria-hidden="true">Decorative icon</span>

<!-- Hide visually but keep focusable -->
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

<span class="sr-only">Screen reader only text</span>
```

## Common Pitfalls

### DON'T: Ignore Keyboard Users

```html
<!-- Bad: Click-only interactions -->
<div onclick="handleClick()">
  Click me
</div>

<!-- Good: Keyboard accessible -->
<button onclick="handleClick()">
  Click me
</button>

<!-- Or add keyboard support -->
<div
  role="button"
  tabindex="0"
  onclick="handleClick()"
  onkeydown="if(event.key === 'Enter' || event.key === ' ') { handleClick() }}"
>
  Click me
</div>
```

### DON'T: Remove Focus Indicators

```css
/* Bad: Removes focus indicator */
:focus {
  outline: none;
}

/* Good: Custom focus indicator */
:focus {
  outline: 3px solid #0066cc;
  outline-offset: 2px;
}

/* Or use :focus-visible for mouse-only */
:focus:not(:focus-visible) {
  outline: none;
}
:focus-visible {
  outline: 3px solid #0066cc;
}
```

## Keyboard Navigation Testing

### Manual Testing

```bash
# Test keyboard navigation
1. Tab through all elements
2. Verify logical focus order
3. Test arrow keys in menus
4. Test Escape key to close modals
5. Test Enter/Space to activate elements
6. Test Home/End in lists
```

### Automated Testing

```bash
# Use axe DevTools
# https://www.deque.com/axe/

# Use Lighthouse
npx lighthouse https://example.com --view
```

## Related Skills

- [Accessibility](../skills/accessibility/SKILL.md) - Comprehensive a11y guide

## Related Patterns

- [ARIA Attributes](../aria_attributes.md) - ARIA patterns
- [HTML/CSS](../html-css/SKILL.md) - Semantic HTML patterns
