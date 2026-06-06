---
name: mobile-ux
description: >
  Mobile-first UX and modern design patterns. ACTIVATE when: building UI
  components, designing forms, implementing booking wizards, or optimising
  for conversion. Covers tap targets, autofill, micro-animations, and
  premium design principles.
---

# Mobile-First UX Skill

## When to Use
- Building any user-facing UI
- Designing forms or multi-step wizards
- Optimising for mobile conversion
- Implementing animations or interactions

## Instructions

### Step 1: Thumb-friendly targets
- Minimum 44×44px for ALL buttons and interactive elements
- Time slot buttons: at least 48px tall
- Sufficient spacing between tap targets (8px minimum)

### Step 2: Autofill-friendly forms
```html
<input name="name" autoComplete="name" />
<input name="email" autoComplete="email" type="email" />
<input name="phone" autoComplete="tel" type="tel" />
```

### Step 3: Progress indicators
"Step 2 of 4" reduces abandonment by 20%.

### Step 4: Premium design principles
- Modern typography: Google Fonts (Inter, Outfit, Roboto) not browser defaults
- Curated palettes, not generic red/blue/green
- Smooth gradients, subtle glassmorphism
- Micro-animations: hover effects, selection transitions
- Skeleton screens for loading, not spinners
- Dark/light mode support

### Step 5: Sticky CTAs
```css
.cta-bar { position: sticky; bottom: 0; z-index: 10; }
```

### Step 6: Single column on mobile
No side-by-side layouts below 768px.

## Conversion targets
| Metric | Target |
|--------|--------|
| Visit → service selection | 70%+ |
| Service → date/time | 60%+ |
| Date → form completion | 50%+ |
| Form → payment | 80%+ |
| Overall | 15–25% |
