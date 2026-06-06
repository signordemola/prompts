---
name: client-file-delivery
description: >
  Secure file delivery for service businesses (photography, creative studios).
  ACTIVATE when: building client download portals, integrating with gallery 
  platforms (Pic-Time, ShootProof), generating signed URLs, or managing large 
  file storage with Cloudflare R2/S3.
---

# Client File Delivery Skill

## When to Use
- Building a client portal for file downloads
- Generating secure, expiring download links
- Storing/delivering large files (photos, videos, documents)
- Integrating with gallery platforms (Pic-Time, ShootProof, Pixieset)
- Setting up Cloudflare R2 or S3 for file storage

<HARD-GATE>
**⛔ MANDATORY — ALL FILE URLS MUST BE SIGNED AND EXPIRING.**
Never expose raw storage URLs. Always use presigned URLs with expiration (1-24 hours). Never store access credentials on the client side.
</HARD-GATE>

## Architecture Decision

| | Pic-Time/Gallery Platform | Custom R2/S3 Delivery | Hybrid |
|---|---|---|---|
| **Best for** | Client proofing, print sales, albums | Custom branded portal, B2B delivery | Keep gallery for proofing + custom for final delivery |
| **Control** | Low — platform UI | Full — your UI | Mixed |
| **Cost** | Platform subscription | Storage only (R2 = free egress) | Both |
| **2TB+ archives** | Expensive at scale | Very affordable on R2 | Archive on R2, active on Pic-Time |

> **Default for photography studios:** Hybrid — Pic-Time for client-facing galleries, Cloudflare R2 for archival and custom file delivery.

## Cloudflare R2 Setup (S3-Compatible, Zero Egress Fees)

### Why R2
- S3-compatible API (use standard AWS SDK)
- **Zero egress fees** — no charge for downloads
- Global edge caching via Cloudflare
- Perfect for large files (photos, videos)

### Bucket Structure

```
r2-bucket/
├── tenants/
│   └── {tenantSlug}/
│       └── clients/
│           └── {clientId}/
│               └── sessions/
│                   └── {sessionId}/
│                       ├── delivery/        ← Final files for client
│                       │   ├── image001.jpg
│                       │   └── image002.jpg
│                       ├── proofs/          ← Watermarked proofs
│                       └── archive/         ← RAW/original files
```

### Signed URL Generation

```typescript
// lib/storage.ts
import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const r2 = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
  },
});

// Generate a download URL (expires in 1 hour)
export async function getDownloadUrl(key: string, expiresIn = 3600): Promise<string> {
  const command = new GetObjectCommand({
    Bucket: process.env.R2_BUCKET!,
    Key: key,
  });
  return getSignedUrl(r2, command, { expiresIn });
}

// Generate an upload URL (for client uploads if needed)
export async function getUploadUrl(key: string, contentType: string): Promise<string> {
  const command = new PutObjectCommand({
    Bucket: process.env.R2_BUCKET!,
    Key: key,
    ContentType: contentType,
  });
  return getSignedUrl(r2, command, { expiresIn: 3600 });
}
```

### Download Link API

```typescript
// app/api/files/[fileId]/download/route.ts
import { getDownloadUrl } from '@/lib/storage';

export async function GET(request: Request, { params }: { params: { fileId: string } }) {
  const { fileId } = params;
  
  // Verify access (token or auth)
  const token = new URL(request.url).searchParams.get('token');
  const delivery = await prisma.fileDelivery.findFirst({
    where: { 
      id: fileId,
      accessToken: token,
      expiresAt: { gt: new Date() }
    }
  });
  
  if (!delivery) {
    return Response.json({ error: 'Invalid or expired link' }, { status: 403 });
  }
  
  const url = await getDownloadUrl(delivery.storageKey);
  return Response.redirect(url);
}
```

## Data Model

```prisma
model FileDelivery {
  id           String   @id @default(cuid())
  
  // Client
  clientId     String
  client       Client   @relation(fields: [clientId], references: [id])
  sessionName  String   // "Wedding — June 2026"
  
  // Access
  accessToken  String   @unique @default(cuid())  // For secure link
  expiresAt    DateTime // Link expiration
  
  // Files
  files        DeliveryFile[]
  
  // Tracking
  viewedAt     DateTime?
  downloadedAt DateTime?
  
  // Notification
  notifiedAt   DateTime?
  
  createdAt    DateTime @default(now())
  
  @@index([accessToken])
  @@index([clientId])
}

model DeliveryFile {
  id          String       @id @default(cuid())
  deliveryId  String
  delivery    FileDelivery @relation(fields: [deliveryId], references: [id])
  
  filename    String       // "IMG_2847.jpg"
  storageKey  String       // "tenants/hem/clients/xyz/sessions/abc/delivery/IMG_2847.jpg"
  sizeBytes   BigInt
  mimeType    String
  
  @@index([deliveryId])
}
```

## Client Notification

```typescript
// Notify client that files are ready
async function notifyFilesReady(delivery: FileDelivery) {
  const downloadUrl = `${process.env.APP_URL}/download/${delivery.accessToken}`;
  
  await resend.emails.send({
    from: 'files@yourstudio.com',
    to: delivery.client.email,
    subject: `Your files are ready — ${delivery.sessionName}`,
    html: `
      <h2>Your files are ready!</h2>
      <p>Hi ${delivery.client.firstName},</p>
      <p>Your ${delivery.sessionName} files are ready for download.</p>
      <a href="${downloadUrl}" style="...">Download Files</a>
      <p><small>This link expires on ${delivery.expiresAt.toLocaleDateString()}</small></p>
    `
  });
  
  await prisma.fileDelivery.update({
    where: { id: delivery.id },
    data: { notifiedAt: new Date() }
  });
}
```

## Zip Download (Multiple Files)

```typescript
// For downloading multiple files as a zip
import archiver from 'archiver';

export async function GET(request: Request) {
  const token = new URL(request.url).searchParams.get('token');
  const delivery = await prisma.fileDelivery.findFirst({
    where: { accessToken: token, expiresAt: { gt: new Date() } },
    include: { files: true }
  });
  
  if (!delivery) return Response.json({ error: 'Expired' }, { status: 403 });
  
  // Stream zip to client
  const archive = archiver('zip', { zlib: { level: 5 } });
  
  for (const file of delivery.files) {
    const url = await getDownloadUrl(file.storageKey);
    const response = await fetch(url);
    archive.append(response.body, { name: file.filename });
  }
  
  archive.finalize();
  
  return new Response(archive as any, {
    headers: {
      'Content-Type': 'application/zip',
      'Content-Disposition': `attachment; filename="${delivery.sessionName}.zip"`
    }
  });
}
```

## Storage Cost Optimization

| Tier | What | Where | Why |
|---|---|---|---|
| **Hot** | Current client deliveries (< 90 days) | R2 standard | Fast access |
| **Archive** | Completed projects | R2 Infrequent Access or cold | Low cost |
| **Gallery** | Client-facing proofs/albums | Pic-Time | UX optimized |

```typescript
// Cron job: move old deliveries to archive tier
// Run monthly
async function archiveOldDeliveries() {
  const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  
  const old = await prisma.fileDelivery.findMany({
    where: { createdAt: { lt: cutoff }, archived: false },
    include: { files: true }
  });
  
  for (const delivery of old) {
    for (const file of delivery.files) {
      // Move from delivery/ to archive/ prefix
      const archiveKey = file.storageKey.replace('/delivery/', '/archive/');
      await copyObject(file.storageKey, archiveKey);
      await deleteObject(file.storageKey);
      
      await prisma.deliveryFile.update({
        where: { id: file.id },
        data: { storageKey: archiveKey }
      });
    }
  }
}
```

## NEVER
- ❌ Expose raw R2/S3 URLs (always use signed URLs)
- ❌ Set signed URL expiration longer than 24 hours
- ❌ Store R2 credentials on the client side
- ❌ Use sequential IDs for access tokens (use cuid/nanoid)
- ❌ Skip access verification before generating download URLs
- ❌ Store file metadata without the storage key
