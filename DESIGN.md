---
name: Kinetic Campus
colors:
  surface: '#fbf8ff'
  surface-dim: '#dcd9e0'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f2fa'
  surface-container: '#f0ecf4'
  surface-container-high: '#eae7ee'
  surface-container-highest: '#e4e1e9'
  on-surface: '#1b1b20'
  on-surface-variant: '#464552'
  inverse-surface: '#303035'
  inverse-on-surface: '#f3eff7'
  outline: '#777684'
  outline-variant: '#c7c5d4'
  surface-tint: '#5352b7'
  primary: '#5352b7'
  on-primary: '#ffffff'
  primary-container: '#8c8cf5'
  on-primary-container: '#211c86'
  inverse-primary: '#c2c1ff'
  secondary: '#3a3fe5'
  on-secondary: '#ffffff'
  secondary-container: '#565cfe'
  on-secondary-container: '#faf7ff'
  tertiary: '#5a5b83'
  on-tertiary: '#ffffff'
  tertiary-container: '#9393be'
  on-tertiary-container: '#2a2c50'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c2c1ff'
  on-primary-fixed: '#0b006b'
  on-primary-fixed-variant: '#3a399e'
  secondary-fixed: '#e1e0ff'
  secondary-fixed-dim: '#bfc1ff'
  on-secondary-fixed: '#03006d'
  on-secondary-fixed-variant: '#2223d3'
  tertiary-fixed: '#e1e0ff'
  tertiary-fixed-dim: '#c3c3f0'
  on-tertiary-fixed: '#16183b'
  on-tertiary-fixed-variant: '#424369'
  background: '#fbf8ff'
  on-background: '#1b1b20'
  surface-variant: '#e4e1e9'
typography:
  display-lg:
    fontFamily: Bricolage Grotesque
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Bricolage Grotesque
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Bricolage Grotesque
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Bricolage Grotesque
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 21px
  body-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  caption:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system embodies youthful, energetic peer-to-peer ride sharing tailored for campus communities. It bridges dynamic student connection with absolute safety and dependability. By combining expressive, spirited headline typography with airy, welcoming, pillow-soft surfaces, the interface transforms logistical transit into an inviting social ritual.

The visual style blends modern soft-minimalism with subtle tactile elements: generous negative space, smooth pill shapes, airy tinted elevations, and high-legibility contrasts. The emotional response should be reassuring, unpretentious, spirited, and effortless.

## Colors

The palette balances energetic indigo-violet tones with clear functional surfaces:

- **Primary (`#8C8CF5` - Periwinkle):** Serves as the signature accent, energetic highlights, active states, and focal badges.
- **Secondary (`#1F1FD1` - Royal Blue):** Anchors high-priority actions, interactive links, map routes, and verified safety verification badging.
- **Tertiary (`#C9C9F7` - Pale Lavender):** Backdrops, soft badge fills, pill containers, and light divider tints.
- **Neutrals:**
  - Base Ink: `#0D0D12` (dominant display and headings).
  - Secondary Text: `#6B6B7B` (subtitles, metadata, and supporting labels).
  - Muted Text: `#9A9AAA` (placeholders, disabled states, unselected icons).
  - Surface White: `#FFFFFF` (cards, floating sheets, interactive inputs).
  - Surface Stroke: `#DAD8E3` (subtle structural borders).
  - Dark Accent Button: `#0A0A0A` (expressive, high-impact CTA alternatives).

### Canvas Gradients
Screens utilize a soft vertical gradient background for mobile viewports: starting with `#B7ACEB` at the top app bar area, diffusing into `#E6E1F8` through the mid-scroll, and settling into an airy `#F7F5FD` along the bottom navigation surface.

## Typography

Typography balances character and clarity:
- **Headlines (`Bricolage Grotesque`):** Delivers a charismatic, rhythmic presence across trip titles, route confirmations, and hero moments. Tight tracking creates a cohesive graphic appearance.
- **Body & Labels (`Be Vietnam Pro`):** Delivers clean humanist geometry optimized for mobile readability, timestamps, fare calculations, and ride details.

Numbers inside ride metrics and fares retain proportional lining figures for legibility against dynamic map elements.

## Layout & Spacing

Designed primarily for mobile portrait orientation (target canvas: 390px x 844px) with safe margin accommodations:

- **Horizontal Margins:** Fixed `1.5rem` (24px) padding along left and right canvas edges to secure thumb reach and prevent edge collisions.
- **Vertical Rhythm:** Structured systematically in increments of `1rem` (16px) or `1.5rem` (24px) for distinct module separations.
- **Internal Component Spacing:**
  - Compact tags/badges: `0.25rem` to `0.5rem`.
  - Input field padding: `0.75rem` vertical by `1rem` horizontal.
  - Card interiors: `1.25rem` (20px) to `1.5rem` (24px).
- **Responsive Adaptations:** Content centers in a maximum 480px width shell on tablet/desktop viewports, preserving mobile-first ergonomics.

## Elevation & Depth

Visual hierarchy uses luminous tinted surfaces and wide ambient diffusions rather than muddy drop shadows:

- **Ambient Tinted Shadows:** Floating cards and bottom action trays use a diffuse shadow: `0px 12px 24px rgba(31, 31, 209, 0.06)` or `0px 10px 24px rgba(107, 107, 123, 0.08)`. This keeps surfaces feeling weightless and clean.
- **Surface Layering:** Elevated cards rest on pure white (`#FFFFFF`) with a hairline border (`1px solid #DAD8E3`) to maintain crisp boundaries across gradient backdrops.
- **Backdrop Frost:** Sticky top headers and bottom navigation bars implement `backdrop-filter: blur(16px)` over a 85% alpha-translucent fill (`rgba(247, 245, 253, 0.85)`).

## Shapes

The interface embraces a pill-shaped, organic visual geometry:
- **Buttons & Chips:** Full pill radius (`9999px` or standard `28px` on control heights).
- **Cards & Surface Panels:** Expansive `24px` to `32px` corner radii, generating a friendly and tactile aesthetic.
- **Input Fields:** Semi-pill rounded radius (`16px` to `24px`) matching the softness of actionable cards.
- **Map Overlays & Sheets:** Top-left and top-right radii set to `28px` for bottom drawer expansions.

## Components

### Buttons
- **Primary Action Button:** Full pill height of 52px or 56px, filled in `#1F1FD1` or bold dark `#0A0A0A`, text set in `label-md` (white), with subtle elevation. Active states trigger a scale reduction to `0.98`.
- **Secondary Action Button:** Surface white fill, `1px solid #DAD8E3`, text in `#0D0D12`.
- **Ghost/Tertiary:** Full pill, transparent background, text in `#1F1FD1`, with `#C9C9F7` active fill.

### Chips & Badges
- **Status Pills:** Height of 28px–32px, full pill radius (`9999px`), padding `6px 14px`.
- **Verified Student Badge:** `#C9C9F7` background with `#1F1FD1` text and micro checkmark icon.
- **Filter Chips:** Inactive in `#FFFFFF` with `#DAD8E3` outline; active state filled in `#8C8CF5` with `#FFFFFF` text.

### Cards (Ride Card & Driver Snippet)
- **Container:** Pure `#FFFFFF` background, `24px` border radius, `1px solid #DAD8E3` perimeter stroke, and the soft periwinkle ambient shadow.
- **Layout:** Vertical card containing driver micro-avatar, depart/arrival timeline node, seat counter chip, and fare readout rendered in `headline-md`.

### Input Fields
- **Search & Destination Fields:** Height of 52px, `16px` border-radius, background `#FFFFFF`, bordered with `#DAD8E3`. Focused state transitions border to `#8C8CF5` with a soft outer ring. Placeholder text styled in `#9A9AAA`.

### Checkboxes & Selection Controls
- **Radio Buttons / Carpool Selection:** Dual-ring pill or circular selectors. Active ring colored in `#1F1FD1` with inner solid circle.
- **Toggle Switches:** 32px height, full pill track; active thumb rests against an active `#8C8CF5` track.

### Ride Meta Route Node
- Vertical timeline element using a solid `#1F1FD1` start node, dashed `#C9C9F7` path line, and a pill stop point to display pick-up and campus drop-off clearly.