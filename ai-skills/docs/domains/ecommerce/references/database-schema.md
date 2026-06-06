# Full Ecommerce Database Schema

## Complete Prisma Schema

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ═══════════════════════════════════════════
// PRODUCT CATALOG
// ═══════════════════════════════════════════

model Product {
  id              String    @id @default(cuid())
  slug            String    @unique
  name            String
  description     String
  descriptionHtml String?
  status          String    @default("DRAFT") // DRAFT | ACTIVE | ARCHIVED
  category        String?
  tags            String[]
  isDigital       Boolean   @default(false)
  sortOrder       Int       @default(0)
  metaTitle       String?
  metaDescription String?

  variants        ProductVariant[]
  images          ProductImage[]
  reviews         Review[]

  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
  deletedAt       DateTime?
}

model ProductVariant {
  id                String   @id @default(cuid())
  productId         String
  product           Product  @relation(fields: [productId], references: [id])
  sku               String   @unique
  name              String   // "Small / Black", "Default"
  
  // Pricing — smallest currency unit
  priceGBP          Int
  priceUSD          Int
  priceCAD          Int
  compareAtPriceGBP Int?     // "Was £X" for sale display
  compareAtPriceUSD Int?
  compareAtPriceCAD Int?

  // Options
  option1           String?  // "Small", "Red"
  option2           String?
  option3           String?  // max 3 axes

  // Inventory
  trackInventory    Boolean  @default(true)
  inventoryQuantity Int      @default(0)
  lowStockThreshold Int      @default(5)
  allowBackorder    Boolean  @default(false)
  
  // Shipping
  weightGrams       Int?
  lengthCm          Float?
  widthCm           Float?
  heightCm          Float?

  isActive          Boolean  @default(true)
  sortOrder         Int      @default(0)

  lineItems         LineItem[]
  cartItems         CartItem[]

  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt

  @@index([productId])
}

model ProductImage {
  id        String  @id @default(cuid())
  productId String
  product   Product @relation(fields: [productId], references: [id])
  url       String
  altText   String
  isPrimary Boolean @default(false)
  sortOrder Int     @default(0)

  @@index([productId])
}

// ═══════════════════════════════════════════
// CART
// ═══════════════════════════════════════════

model Cart {
  id        String     @id @default(cuid())
  sessionId String?    @unique // anonymous users
  userId    String?    // authenticated users
  items     CartItem[]
  expiresAt DateTime   // 30 days from last activity
  createdAt DateTime   @default(now())
  updatedAt DateTime   @updatedAt

  @@index([userId])
  @@index([expiresAt])
}

model CartItem {
  id        String         @id @default(cuid())
  cartId    String
  cart      Cart           @relation(fields: [cartId], references: [id], onDelete: Cascade)
  variantId String
  variant   ProductVariant @relation(fields: [variantId], references: [id])
  quantity  Int

  createdAt DateTime       @default(now())
  updatedAt DateTime       @updatedAt

  @@unique([cartId, variantId])
}

// ═══════════════════════════════════════════
// ORDERS
// ═══════════════════════════════════════════

model Order {
  id              String   @id @default(cuid())
  orderNumber     Int      @unique @default(autoincrement())
  
  // Customer
  customerEmail   String
  customerName    String
  userId          String?  // null for guest checkout
  
  // Status
  status          String   @default("PENDING")
  // PENDING | CONFIRMED | PROCESSING | SHIPPED | DELIVERED | COMPLETED | CANCELLED
  
  // Pricing — all in smallest unit, currency recorded
  currency        String   // "gbp" | "usd" | "cad"
  subtotal        Int      // sum of line items
  shippingAmount  Int
  taxAmount       Int
  discountAmount  Int      @default(0)
  total           Int      // subtotal + shipping + tax - discount
  
  // Payment
  stripeSessionId   String?  @unique
  stripePaymentId   String?  @unique
  paymentStatus     String   @default("UNPAID") // UNPAID | PAID | REFUNDED | PARTIALLY_REFUNDED
  
  // Addresses
  shippingAddressId String?
  shippingAddress   Address? @relation("ShippingAddress", fields: [shippingAddressId], references: [id])
  billingAddressId  String?
  billingAddress    Address? @relation("BillingAddress", fields: [billingAddressId], references: [id])
  
  // Shipping
  shippingMethod    String?  // "standard" | "express"
  
  // Discount
  couponId          String?
  couponCode        String?
  
  // Notes
  customerNote      String?
  internalNote      String?
  
  lineItems         LineItem[]
  fulfillments      Fulfillment[]
  returns           Return[]
  
  cancelledAt       DateTime?
  cancelledBy       String?
  
  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt

  @@index([customerEmail])
  @@index([status])
  @@index([createdAt])
}

model LineItem {
  id              String         @id @default(cuid())
  orderId         String
  order           Order          @relation(fields: [orderId], references: [id])
  variantId       String
  variant         ProductVariant @relation(fields: [variantId], references: [id])
  
  // Snapshot at purchase time — NEVER reference current product price
  productName     String
  variantName     String
  sku             String
  unitPrice       Int           // price at time of purchase
  quantity        Int
  totalPrice      Int           // unitPrice * quantity
  
  // Fulfillment tracking
  fulfilledQty    Int           @default(0)
  
  createdAt       DateTime      @default(now())

  @@index([orderId])
}

model Address {
  id          String  @id @default(cuid())
  firstName   String
  lastName    String
  line1       String
  line2       String?
  city        String
  state       String? // state/province/county
  postalCode  String
  country     String  // "GB" | "US" | "CA"
  phone       String?

  shippingOrders Order[] @relation("ShippingAddress")
  billingOrders  Order[] @relation("BillingAddress")

  createdAt   DateTime @default(now())
}

// ═══════════════════════════════════════════
// FULFILLMENT
// ═══════════════════════════════════════════

model Fulfillment {
  id             String   @id @default(cuid())
  orderId        String
  order          Order    @relation(fields: [orderId], references: [id])
  status         String   @default("PENDING")
  // PENDING | PICKED | PACKED | SHIPPED | DELIVERED
  trackingNumber String?
  carrier        String?  // "royal-mail" | "usps" | "canada-post"
  trackingUrl    String?
  shippedAt      DateTime?
  deliveredAt    DateTime?
  items          Json     // [{ lineItemId, quantity }]
  
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt

  @@index([orderId])
}

// ═══════════════════════════════════════════
// RETURNS
// ═══════════════════════════════════════════

model Return {
  id           String   @id @default(cuid())
  orderId      String
  order        Order    @relation(fields: [orderId], references: [id])
  status       String   @default("REQUESTED")
  // REQUESTED | APPROVED | SHIPPED_BACK | RECEIVED | REFUNDED | REJECTED
  items        Json     // [{ lineItemId, quantity, reasonCode }]
  refundAmount Int?
  stripeRefundId String?
  internalNote String?
  
  requestedAt  DateTime @default(now())
  approvedAt   DateTime?
  receivedAt   DateTime?
  refundedAt   DateTime?

  @@index([orderId])
}

// ═══════════════════════════════════════════
// DISCOUNTS
// ═══════════════════════════════════════════

model Coupon {
  id              String   @id @default(cuid())
  code            String?  @unique // null = automatic discount
  type            String   // PERCENTAGE | FIXED_AMOUNT | FREE_SHIPPING | BUY_X_GET_Y
  value           Int      // 10 = 10%, or 500 = £5.00
  minOrderAmount  Int?     // pence/cents
  maxDiscountAmount Int?   // cap for percentage
  maxUses         Int?
  maxUsesPerUser  Int?     @default(1)
  usedCount       Int      @default(0)
  
  // Scope
  appliesTo       String   @default("ALL") // ALL | SPECIFIC_PRODUCTS | SPECIFIC_CATEGORIES
  productIds      String[]
  categoryIds     String[]
  
  // BXGY config
  buyQuantity     Int?     // "Buy X"
  getQuantity     Int?     // "Get Y"
  getProductIds   String[] // which products are free/discounted
  
  // Scheduling
  startsAt        DateTime
  endsAt          DateTime
  isActive        Boolean  @default(true)
  isAutomatic     Boolean  @default(false)
  priority        Int      @default(0) // higher = applied first
  
  createdAt       DateTime @default(now())
}

// ═══════════════════════════════════════════
// REVIEWS
// ═══════════════════════════════════════════

model Review {
  id          String   @id @default(cuid())
  productId   String
  product     Product  @relation(fields: [productId], references: [id])
  orderId     String?  // verified purchase badge
  
  authorName  String
  authorEmail String
  rating      Int      // 1-5
  title       String?
  body        String
  
  status      String   @default("PENDING") // PENDING | APPROVED | REJECTED
  isVerified  Boolean  @default(false)
  
  createdAt   DateTime @default(now())

  @@index([productId])
  @@index([status])
}

// ═══════════════════════════════════════════
// WISHLIST
// ═══════════════════════════════════════════

model WishlistItem {
  id        String   @id @default(cuid())
  userId    String
  productId String
  createdAt DateTime @default(now())

  @@unique([userId, productId])
}

// ═══════════════════════════════════════════
// AUDIT
// ═══════════════════════════════════════════

model AuditLog {
  id          String   @id @default(cuid())
  entityType  String
  entityId    String
  action      String
  oldData     Json?
  newData     Json?
  performedBy String
  createdAt   DateTime @default(now())

  @@index([entityType, entityId])
  @@index([createdAt])
}
```

## Index Decisions

| Index | Why |
|-------|-----|
| `@@unique([cartId, variantId])` on CartItem | Prevent duplicate variants in cart |
| `@@unique([stripeSessionId])` on Order | Idempotent webhook processing |
| `@@unique([stripePaymentId])` on Order | Same |
| `@@index([expiresAt])` on Cart | Fast expired cart cleanup |
| `@@index([customerEmail])` on Order | Fast order history lookup |
| `@@index([status])` on Order | Fast status filtering |
| `@@index([productId])` on Review | Fast product review listing |
| `@@unique([userId, productId])` on WishlistItem | One wishlist entry per product |
| `@@unique([sku])` on ProductVariant | No duplicate SKUs |

## Key Pattern: Price Snapshot

```ts
// When creating an order, ALWAYS snapshot prices:
const lineItem = {
  productName: variant.product.name,
  variantName: variant.name,
  sku: variant.sku,
  unitPrice: variant.priceGBP,    // frozen at purchase time
  quantity: cartItem.quantity,
  totalPrice: variant.priceGBP * cartItem.quantity,
}
// NEVER: lineItem.price = variant.currentPrice (stale reference)
```

## Soft Delete Pattern

Same as booking domain — `deletedAt` on Product. Never hard-delete products with existing orders.
