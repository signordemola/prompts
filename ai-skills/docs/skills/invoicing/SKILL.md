---
name: invoicing
description: >
  Invoice generation and payment tracking for service businesses. ACTIVATE when:
  generating PDF invoices, tracking deposits/balances, integrating Stripe Invoicing API,
  handling tax across jurisdictions (CA/US/UK), or building invoice list/detail views.
---

# Invoicing Skill

## When to Use
- Generating invoices for completed services
- Tracking deposits applied vs balance due
- Building invoice list/detail views in admin dashboard
- Setting up automated invoice emails
- Handling tax (GST/HST Canada, VAT UK, sales tax US)

<HARD-GATE>
**⛔ MANDATORY — ALL INVOICE CALCULATIONS MUST BE SERVER-SIDE.**
Never calculate totals, tax, or discounts on the client. Never accept amounts from the frontend. Store all monetary values in smallest currency unit (cents/pence). Invoice numbers must be sequential and gap-free per legal requirements.
</HARD-GATE>

## Decision: Stripe Invoicing API vs Custom

| | Stripe Invoicing API | Custom PDF Generation |
|---|---|---|
| **Best for** | Recurring billing, subscriptions, auto-collection | One-off service invoices, custom branding |
| **Tax** | Stripe Tax handles automatically | You calculate and store |
| **Payment** | Built-in payment link on invoice | You link to PaymentIntent |
| **Branding** | Limited customization | Full control |
| **Complexity** | Low — Stripe handles PDF + email | Higher — you build everything |

> **Default for service businesses:** Custom PDF for one-off services, Stripe Invoicing for retainers/packages.

## Data Model

```prisma
model Invoice {
  id              String        @id @default(cuid())
  invoiceNumber   String        @unique  // INV-2026-0001
  status          InvoiceStatus @default(DRAFT)
  
  // Client
  clientId        String
  client          Client        @relation(fields: [clientId], references: [id])
  
  // Amounts (all in smallest currency unit)
  subtotal        Int           // Before tax
  taxAmount       Int           // Calculated tax
  discountAmount  Int           @default(0)
  total           Int           // subtotal + tax - discount
  depositApplied  Int           @default(0)  // From booking deposit
  balanceDue      Int           // total - depositApplied
  
  // Currency
  currency        String        @default("cad")  // ISO 4217 lowercase
  
  // Tax
  taxRate         Decimal?      // e.g., 0.13 for 13% HST
  taxLabel        String?       // "HST", "VAT", "Sales Tax"
  
  // Dates
  issuedAt        DateTime      @default(now())
  dueAt           DateTime      // Net 7, Net 15, Net 30
  paidAt          DateTime?
  
  // Payment
  stripePaymentId String?
  stripeInvoiceId String?
  
  // Relations
  lineItems       InvoiceLineItem[]
  appointmentId   String?       // Link to booking if applicable
  
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt
  
  @@index([clientId])
  @@index([status])
}

enum InvoiceStatus {
  DRAFT
  SENT
  VIEWED
  PAID
  OVERDUE
  CANCELLED
  REFUNDED
}

model InvoiceLineItem {
  id          String   @id @default(cuid())
  invoiceId   String
  invoice     Invoice  @relation(fields: [invoiceId], references: [id])
  
  description String   // "Full Bridal Makeup Session — 3 hours"
  quantity    Int      @default(1)
  unitPrice   Int      // In smallest currency unit
  total       Int      // quantity * unitPrice
  
  @@index([invoiceId])
}
```

## Invoice Numbering

```typescript
// Sequential, gap-free numbering per legal requirements
async function nextInvoiceNumber(prisma: PrismaClient): Promise<string> {
  const year = new Date().getFullYear()
  const prefix = `INV-${year}-`
  
  const last = await prisma.invoice.findFirst({
    where: { invoiceNumber: { startsWith: prefix } },
    orderBy: { invoiceNumber: 'desc' }
  })
  
  const seq = last 
    ? parseInt(last.invoiceNumber.replace(prefix, '')) + 1 
    : 1
  
  return `${prefix}${seq.toString().padStart(4, '0')}`
}
```

## PDF Generation

### Decision: Where to Generate

| | Server-Side (FastAPI) | Client-Side (React-PDF) |
|---|---|---|
| **Library** | WeasyPrint or Puppeteer | @react-pdf/renderer |
| **Quality** | High — full CSS control | Good — React components |
| **Branding** | Full custom templates | Full custom components |
| **Best for** | Email attachments, archival | Interactive preview |

> **Default:** Server-side PDF (FastAPI + WeasyPrint) for email. Client-side preview for admin dashboard.

### FastAPI PDF Generation

```python
# FastAPI — PDF from HTML template
from weasyprint import HTML
from jinja2 import Template

@router.get("/invoices/{invoice_id}/pdf")
async def generate_invoice_pdf(invoice_id: str):
    invoice = await get_invoice_with_items(invoice_id)
    
    html = render_invoice_template(invoice)
    pdf = HTML(string=html).write_pdf()
    
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f"inline; filename={invoice.invoiceNumber}.pdf"}
    )
```

### React-PDF Preview (Admin Dashboard)

```tsx
import { Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer';

const InvoicePDF = ({ invoice }: { invoice: Invoice }) => (
  <Document>
    <Page size="A4" style={styles.page}>
      <View style={styles.header}>
        <Text>{invoice.businessName}</Text>
        <Text>Invoice #{invoice.invoiceNumber}</Text>
      </View>
      
      {invoice.lineItems.map(item => (
        <View key={item.id} style={styles.row}>
          <Text>{item.description}</Text>
          <Text>{formatCurrency(item.total, invoice.currency)}</Text>
        </View>
      ))}
      
      <View style={styles.totals}>
        <Text>Subtotal: {formatCurrency(invoice.subtotal, invoice.currency)}</Text>
        <Text>{invoice.taxLabel}: {formatCurrency(invoice.taxAmount, invoice.currency)}</Text>
        {invoice.depositApplied > 0 && (
          <Text>Deposit Applied: -{formatCurrency(invoice.depositApplied, invoice.currency)}</Text>
        )}
        <Text style={styles.bold}>
          Balance Due: {formatCurrency(invoice.balanceDue, invoice.currency)}
        </Text>
      </View>
    </Page>
  </Document>
);
```

## Tax Handling by Jurisdiction

| Jurisdiction | Tax | Rate | Registration Required |
|---|---|---|---|
| **Canada (Ontario)** | HST | 13% | HST number if revenue > $30K CAD |
| **Canada (Alberta)** | GST | 5% | Same |
| **UK** | VAT | 20% | VAT number if revenue > £85K |
| **US (varies)** | Sales Tax | 0-10%+ | State-dependent |

```typescript
function calculateTax(subtotal: number, jurisdiction: string): { amount: number; rate: number; label: string } {
  const taxes: Record<string, { rate: number; label: string }> = {
    'CA-ON': { rate: 0.13, label: 'HST' },
    'CA-AB': { rate: 0.05, label: 'GST' },
    'CA-BC': { rate: 0.12, label: 'GST+PST' },
    'UK': { rate: 0.20, label: 'VAT' },
    'US-NY': { rate: 0.08, label: 'Sales Tax' },
    'US-CA': { rate: 0.0725, label: 'Sales Tax' },
  }
  
  const tax = taxes[jurisdiction] ?? { rate: 0, label: 'Tax' }
  return {
    amount: Math.round(subtotal * tax.rate),
    rate: tax.rate,
    label: tax.label
  }
}
```

## Deposit-to-Invoice Flow

```
Booking Created → Deposit Paid (via Stripe)
                        ↓
              Service Completed
                        ↓
              Invoice Generated
              - subtotal: full service price
              - depositApplied: amount already paid
              - balanceDue: subtotal + tax - deposit
                        ↓
              Invoice Sent (email with PDF + payment link)
                        ↓
              Client Pays Balance → Invoice marked PAID
```

## Email Invoice

```typescript
// Send invoice with PDF attachment via Resend
import { Resend } from 'resend';

async function sendInvoice(invoice: Invoice, pdfBuffer: Buffer) {
  const resend = new Resend(process.env.RESEND_API_KEY);
  
  await resend.emails.send({
    from: 'invoices@yourstudio.com',
    to: invoice.client.email,
    subject: `Invoice ${invoice.invoiceNumber} from ${businessName}`,
    html: renderInvoiceEmail(invoice),
    attachments: [{
      filename: `${invoice.invoiceNumber}.pdf`,
      content: pdfBuffer
    }]
  });
  
  await prisma.invoice.update({
    where: { id: invoice.id },
    data: { status: 'SENT' }
  });
}
```

## NEVER
- ❌ Accept amounts from the client (always calculate server-side)
- ❌ Skip sequential invoice numbering (legal requirement)
- ❌ Store monetary values as floats (use integers in smallest unit)
- ❌ Send invoices without a payment link or instructions
- ❌ Apply deposit twice (check if already applied)
- ❌ Generate invoice before service is confirmed/completed
