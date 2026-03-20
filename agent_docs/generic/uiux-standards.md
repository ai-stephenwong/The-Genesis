<!-- last-reviewed: 2026-03-17 | reviewed-by: Stephen Wong | next-review: 2026-09-17 -->

# UI/UX Standards (Company Standard)

> These rules apply to all projects with a frontend. Do not override without explicit approval.
> Project-specific design references (Figma links, screen inventory) belong in `agent_docs/project/specs/design.md`.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.

---

## Design Principles

1. **Clarity first** — every element must have a clear purpose; remove anything that doesn't aid the user
2. **Consistency** — same interaction must always produce the same result; use the design system, never invent ad-hoc patterns
3. **Feedback** — every user action must have a visible response (loading state, success, error)
4. **Accessibility by default** — accessibility is not a post-launch concern; design and build to WCAG 2.1 AA from day one
5. **Mobile first** — design for the smallest viewport first, then scale up
6. **Least surprise** — follow platform conventions; don't surprise the user with unexpected behaviour
7. **Data minimalism** — show only the data the user needs for the current task; never expose more than necessary `[ISO 27001: 5.12]`

---

## Design System

### Tokens

All visual decisions must use design tokens — never hardcode values in components.

| Token Category | Examples | Rule |
|---|---|---|
| Colour | `--color-primary`, `--color-error` | Define in one place; reference everywhere |
| Spacing | `--space-1` (4px) through `--space-16` (64px) | Use 4px base grid |
| Typography | `--font-size-sm`, `--font-weight-bold` | Define scale; never arbitrary px sizes |
| Border radius | `--radius-sm`, `--radius-lg` | Consistent rounding per component type |
| Shadow | `--shadow-card`, `--shadow-modal` | No ad-hoc box-shadow values |
| Z-index | `--z-modal`, `--z-tooltip` | Named layers; no magic numbers |
| Breakpoints | `--bp-sm` (640px), `--bp-md` (768px), `--bp-lg` (1024px), `--bp-xl` (1280px) | Consistent across the project |

### Component Library

- Use the project-approved component library (defined in `agent_docs/project/stack.md`)
- Never create a custom component if the approved library already has one
- Custom components must be documented with usage examples
- Component variants must be exhaustively defined — do not create one-off styles inline

---

## Accessibility
`WCAG 2.1 AA | ISO 27001: 5.12`

### Requirements (all mandatory)

| Requirement | Standard | Notes |
|---|---|---|
| Colour contrast (text) | Minimum 4.5:1 (AA) | Use contrast checker before finalising palette |
| Colour contrast (large text / UI) | Minimum 3:1 | Large text = 18pt or 14pt bold |
| Keyboard navigation | All interactive elements reachable and operable | Tab order must be logical |
| Focus indicator | Visible on all focusable elements | Never `outline: none` without a custom replacement |
| Screen reader | All non-text content has text alternative | `alt`, `aria-label`, `aria-describedby` |
| Form labels | Every input has an associated `<label>` | No placeholder-only labels |
| Error messages | Errors identified in text, not colour alone | e.g. "Required field" not just red border |
| Motion | Respect `prefers-reduced-motion` | Disable or reduce animations |
| Touch targets | Minimum 44×44px | Applies to buttons, links, icons |
| Language | `lang` attribute set on `<html>` | Required for screen readers |

### ARIA Usage

- Use native HTML elements before reaching for ARIA (`<button>` not `<div role="button">`)
- Do not use ARIA roles that conflict with the native element's semantics
- Test with at least one screen reader (VoiceOver / NVDA) before release

---

## Responsive Design

- **Mobile first**: base styles target mobile; use `min-width` media queries to scale up
- **Breakpoints**: use the token-defined breakpoints — no arbitrary values
- **Fluid layouts**: prefer `%`, `fr`, `clamp()` over fixed pixel widths
- **Images**: always use responsive images (`srcset`, `sizes`, or `next/image`)
- **Tables**: on small screens, consider card layout or horizontal scroll with visible scroll indicator
- **Touch**: design tap targets to 44×44px minimum; avoid hover-only interactions on mobile

---

## Typography

- Maximum **2 typefaces** per project (one for headings, one for body)
- Use a **typographic scale** (e.g. 12 / 14 / 16 / 20 / 24 / 32 / 40 / 48px) — no arbitrary sizes
- Line height: body text minimum 1.5; headings minimum 1.2
- Line length: 60–80 characters for body text (use `max-width` on text blocks)
- Avoid all-caps for body text; use sparingly for labels only
- Never use `<b>` or `<i>` for semantic meaning — use `<strong>` and `<em>`

---

## Colour

- Define a palette: primary, secondary, neutral, success, warning, error, info
- Every colour must pass contrast requirements before use (see Accessibility section)
- Do not convey information by colour alone — always pair with text or icon
- Dark mode: if required, define a separate token set — never invert colours manually

---

## Iconography

- Use a single icon library per project (defined in `agent_docs/project/stack.md`)
- All icons used as standalone actions must have an `aria-label` or visible text label
- Icon size must align to the spacing scale (16, 20, 24px most common)
- Do not use emoji as UI icons in production interfaces

---

## Forms

- Every field must have a visible `<label>` — placeholder text is not a label
- Show validation errors inline, adjacent to the relevant field
- Error message format: specific and actionable ("Enter a valid email address" not "Invalid input")
- Required fields must be marked — use `*` with a legend, not colour alone
- Auto-complete attributes must be set on common fields (`email`, `name`, `tel`, `address`)
- Never disable the browser's native form validation without replacing it entirely
- Password fields must offer a show/hide toggle

### Input Field Colour Contract (mandatory)

Input fields must always have **both** text colour and background colour explicitly set together — never rely on inheritance for either property independently:

- **Text colour and background colour must be defined as a pair** in the design token or component stylesheet — if you change one, you must update the other
- Input text must achieve minimum **4.5:1 contrast ratio** against the input background in all states: default, focus, disabled, error, and dark mode
- Placeholder text must achieve minimum **3:1 contrast ratio** against the input background (WCAG 1.4.3)
- **Never** assume input text colour inherits correctly from a parent theme — different browsers, OS themes (e.g. macOS dark mode), and CSS resets can override input colours unpredictably
- The design review checklist must include a contrast check for input text vs input background in every theme variant (light, dark, high-contrast if applicable)
- Disabled input fields must have visibly reduced contrast to communicate non-interactivity — but still meet a minimum 3:1 ratio for legibility

---

## Loading, Error & Empty States

Every data-dependent view must explicitly design all three states:

| State | Requirement |
|---|---|
| **Loading** | Show skeleton screen or spinner; never blank white screen |
| **Error** | Show human-readable message + recovery action (retry, go back, contact support) |
| **Empty** | Explain why it's empty + offer a primary action (e.g. "No items yet — create your first one") |

---

## Navigation

- Maximum **2 levels** of navigation hierarchy (primary nav + sub-nav); deeper hierarchies use breadcrumbs
- Active state must be visually distinct on all nav items
- Mobile navigation must be accessible via keyboard and screen reader
- Breadcrumbs required for pages more than 2 levels deep
- Never rely solely on browser back button for navigation flows

---

## Sensitive Data Display
`ISO 27001: 5.12, 5.13, 8.11`

Data classification must be respected in the UI:

| Classification | Display Rule |
|---|---|
| Public | Display freely |
| Internal | Only shown to authenticated users; no caching by CDN |
| Confidential | Shown only to authorised roles; paginate large datasets; no bulk export without audit log |
| Restricted | **Mask by default** — e.g. `****1234` for card numbers, `••••••••` for passwords; full value never rendered in DOM |

- Never render a full credit card number, password, or secret key in the DOM — even hidden with CSS `[8.11]`
- Sensitive field values must not appear in browser developer tools network tab responses beyond minimum necessary `[8.12]`
- Auto-fill must be disabled on sensitive fields (`autocomplete="off"` or `autocomplete="new-password"`) `[8.5]`
- Session timeout warnings must be shown before auto-logout — do not log out silently `[8.5]`

---

## Internationalisation (i18n)

If the project requires multiple languages:

- All user-facing strings must be externalised from day one — no hardcoded copy in components
- Use the project-approved i18n library (defined in `agent_docs/project/stack.md`)
- Design must accommodate **text expansion** of up to 40% (German / French are ~30% longer than English)
- Date, time, number, and currency formats must use locale-aware formatting (`Intl` API)
- RTL support: if Arabic or Hebrew are required, use logical CSS properties (`margin-inline-start` not `margin-left`)
- Do not rely on colour or iconography that may have different meanings across cultures

---

## Motion & Animation

- All animations must have a purpose — no decorative motion
- Duration: micro-interactions 100–200ms; transitions 200–400ms; never exceed 500ms
- Easing: use ease-in-out for most transitions; avoid linear for anything user-initiated
- Always implement `prefers-reduced-motion` media query to disable or reduce animations
- Never use animation to block or delay user interaction

---

## Design-to-Code Handoff

- All designs must be in the project-approved design tool (defined in `agent_docs/project/specs/design.md`)
- Components in design must match component names in code exactly
- Design must include: all states (default, hover, focus, disabled, error, loading, empty)
- Spacing, colour, and typography must reference design tokens — not arbitrary values
- Design annotations required for: interaction behaviour, animation spec, accessibility notes
- A design is not ready for development until it has been reviewed and all states are defined

---

## Design Review Checklist

Before handing off to development, designer must confirm:

- [ ] All breakpoints designed (mobile, tablet, desktop)
- [ ] All component states defined (default, hover, focus, active, disabled, error, loading, empty)
- [ ] Colour contrast checked and passes WCAG 2.1 AA
- [ ] All interactive elements have visible focus states
- [ ] All form fields have labels and error states
- [ ] Sensitive data fields are masked per data classification rules
- [ ] Loading, error, and empty states designed for all data-dependent views
- [ ] Design tokens used throughout — no hardcoded values
- [ ] i18n: no hardcoded strings; text expansion considered
- [ ] Motion: `prefers-reduced-motion` considered
- [ ] Design reviewed by at least one other team member
