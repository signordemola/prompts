# Booking Wizard Accessibility

## WCAG Requirements

| Principle | What it means for booking |
|-----------|-------------------------|
| **Perceivable** | All info visible + announced to screen readers |
| **Operable** | Full keyboard navigation, no mouse required |
| **Understandable** | Clear error messages, predictable flow |
| **Robust** | Works with assistive tech (NVDA, VoiceOver, JAWS) |

## Step Progress Indicator

```tsx
<nav aria-label="Booking progress">
  <ol role="list">
    {steps.map((step, i) => (
      <li key={step.id} aria-current={i === currentStep ? "step" : undefined}>
        <span aria-hidden="true">{i + 1}</span>
        <span>{step.label}</span>
        {i < currentStep && <span className="sr-only">(completed)</span>}
      </li>
    ))}
  </ol>
</nav>

{/* Announce step changes */}
<h2 id="step-heading">Step {currentStep + 1} of {steps.length}: {steps[currentStep].label}</h2>
<div aria-live="polite" aria-atomic="true" className="sr-only">
  Step {currentStep + 1} of {steps.length}: {steps[currentStep].label}
</div>
```

## Focus Management

```ts
// On step change, focus the step heading
useEffect(() => {
  const heading = document.getElementById("step-heading")
  heading?.focus()
}, [currentStep])

// On error, focus first invalid field
function focusFirstError(errors: Record<string, string>) {
  const firstKey = Object.keys(errors)[0]
  if (firstKey) {
    document.getElementById(firstKey)?.focus()
  }
}
```

## Form Fields

```tsx
{/* Every input needs a visible label */}
<label htmlFor="clientName">Full name</label>
<input
  id="clientName"
  name="clientName"
  type="text"
  required
  aria-required="true"
  aria-invalid={!!errors.clientName}
  aria-describedby={errors.clientName ? "clientName-error" : undefined}
/>
{errors.clientName && (
  <span id="clientName-error" role="alert">{errors.clientName}</span>
)}

{/* Group related fields */}
<fieldset>
  <legend>Health Information</legend>
  {/* allergy fields */}
</fieldset>
```

## Date & Time Selection

```tsx
{/* Slot buttons — announce full context */}
<div role="group" aria-label={`Available times for ${selectedDate}`}>
  {slots.map(slot => (
    <button
      key={slot}
      onClick={() => selectSlot(slot)}
      aria-pressed={selectedSlot === slot}
      aria-label={`Book ${format(slot, "h:mm a")} on ${format(selectedDate, "EEEE d MMMM")}`}
    >
      {format(slot, "h:mm a")}
    </button>
  ))}
</div>

{/* "No slots" state */}
{slots.length === 0 && (
  <p role="status">No available times for this date. Please try another date.</p>
)}
```

## Hold Timer

```tsx
{/* Announce countdown at key thresholds */}
<div
  role="timer"
  aria-live={remainingSeconds <= 60 ? "assertive" : "polite"}
  aria-label={`${Math.floor(remainingSeconds / 60)} minutes ${remainingSeconds % 60} seconds remaining to complete booking`}
>
  {formatTimer(remainingSeconds)}
</div>
```

## Keyboard Requirements

| Action | Key | Must work |
|--------|-----|----------|
| Move between steps | Tab / Shift+Tab | ✅ |
| Select slot | Enter or Space | ✅ |
| Navigate dates | Arrow keys (if calendar) | ✅ |
| Submit form | Enter | ✅ |
| Go back | Back button (visible) | ✅ |
| Cancel | Escape (close modals) | ✅ |

## Checklist

- [ ] All form inputs have visible `<label>` elements
- [ ] Error messages use `role="alert"` and `aria-describedby`
- [ ] Step changes announce via `aria-live`
- [ ] Focus moves to step heading on navigation
- [ ] Slot buttons have full context in `aria-label`
- [ ] Timer announces at 1-minute warning
- [ ] No information conveyed by colour alone
- [ ] Focus indicators visible (min 2px, contrast 3:1)
- [ ] Touch targets ≥ 44x44px
- [ ] Works without JavaScript for critical info

## Walk-In Handling (Owner Dashboard)

```tsx
// Owner adds same-day appointment manually
// Dashboard → "Add Walk-In" button
// → Service picker → time picker → client name/email → create
// → Skips payment (owner collects in person)

async function createWalkIn(data: {
  serviceId: string
  startsAt: Date
  clientName: string
  clientEmail: string
}) {
  const client = await findOrCreateClient(data.clientEmail, data.clientName)
  return prisma.appointment.create({
    data: {
      clientId: client.id,
      serviceId: data.serviceId,
      startsAt: data.startsAt,
      endsAt: addMinutes(data.startsAt, service.durationMinutes),
      status: "CONFIRMED",
      depositAmount: 0,        // no online payment
      totalPrice: service.price,
    }
  })
}
```
