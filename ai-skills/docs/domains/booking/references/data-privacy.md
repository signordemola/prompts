# Data Privacy & GDPR

## Classification of Salon Data

| Data type | Category | Legal basis | Retention |
|-----------|----------|------------|-----------|
| Name, email, phone | Personal data | Legitimate interest | Until erasure request |
| Allergies, skin conditions | **Special category** (health) | **Explicit consent** | 7 years (insurance) |
| Patch test results | **Special category** | **Explicit consent** | 7 years |
| Payment info | Personal (financial) | Contract | Handled by Stripe |
| Booking history | Personal data | Legitimate interest | Until erasure request |
| Owner notes ("prefers silence") | Personal data | Legitimate interest | Until erasure request |

## Consent Collection

```tsx
// Intake form — explicit consent for health data
<fieldset>
  <legend>Health Information</legend>
  <p>We collect allergy and health information for your safety.</p>
  
  <label>
    <input type="checkbox" name="healthConsent" required />
    I consent to my health information being stored for treatment safety
    and insurance purposes (retained for up to 7 years).
    <a href="/privacy">Read our privacy policy →</a>
  </label>
  
  {/* Fields only shown after consent */}
  {healthConsent && (
    <>
      <textarea name="allergies" placeholder="Known allergies..." />
      <input name="patchTestDate" type="date" />
    </>
  )}
</fieldset>
```

**Rules:**
- Checkbox must NOT be pre-checked
- Must link to privacy policy
- Must explain WHY data is collected
- Must state retention period

## Right to Erasure (Article 17)

```ts
// api/data-erasure/route.ts
export async function POST(req: Request) {
  const { email, token } = await req.json()
  // Verify identity (token sent to email)
  
  const client = await prisma.client.findUnique({ where: { email } })
  if (!client) return apiError(404, "Not found")
  
  // What CAN be deleted:
  await prisma.client.update({
    where: { id: client.id },
    data: {
      name: "[REDACTED]",
      phone: null,
      notes: null,
      deletedAt: new Date(),
    }
  })
  
  // What CANNOT be deleted (insurance/legal):
  // - Appointment records (anonymised, retain for accounting)
  // - Intake health data (retain 7 years for insurance)
  
  // Audit the erasure
  await logAudit({
    entityType: "client",
    entityId: client.id,
    action: "data_erasure",
    performedBy: "client_request",
  })
  
  return NextResponse.json({ message: "Data erased" })
}
```

## Cookie Banner

```tsx
// Only needed if you use analytics cookies (GA, Hotjar, etc.)
// Essential cookies (session, auth) don't need consent

// 2026 UK update: statistical cookies MAY be exempt
// But safest to still show banner for tracking cookies
```

## Privacy Policy Must Include

1. What data you collect and why
2. Legal basis (consent for health, legitimate interest for booking)
3. How long you keep it (7 years for health, until erasure for personal)
4. Who has access (staff, payment processor)
5. How to request erasure
6. How to complain (ICO in UK)

## Data Storage Rules

| Rule | Implementation |
|------|---------------|
| Health data separate from booking | `IntakeResponse` table, not on Appointment |
| Encrypt at rest | Neon/Supabase handle this |
| Access control | Health data only on client detail page, not list views |
| Audit access | Log who views health data (if required) |
| Anonymise on delete | Replace name with "[REDACTED]", null phone |

## NEVER
- ❌ Pre-check consent checkboxes
- ❌ Collect health data without explicit consent
- ❌ Hard-delete client records (anonymise instead)
- ❌ Expose health data in list APIs or emails
- ❌ Store raw card numbers (Stripe handles this)
- ❌ Skip privacy policy link on intake forms
