---
name: uploadthing
description: >
  File uploads with Uploadthing v7. ACTIVATE when: adding file uploads,
  image uploads, or document attachments to a Next.js project. Covers
  FileRouter setup, route handlers, and client components.
---

# Uploadthing Skill

## When to Use
- Adding file or image uploads to a Next.js project
- Setting up secure upload endpoints with validation
- Building photo galleries or document upload flows

## Always Load First
- `skills/nextjs-app-router/SKILL.md`

<HARD-GATE>
**⛔ MANDATORY — USE UPLOADTHING_TOKEN (NOT UPLOADTHING_SECRET).**
v7 moved presigned URL generation to your server. The old `UPLOADTHING_SECRET`
is deprecated. Use the single `UPLOADTHING_TOKEN` from the dashboard (API Keys → V7 tab).
</HARD-GATE>

## Setup

```bash
npm install uploadthing @uploadthing/react
```

```env
UPLOADTHING_TOKEN=your_base64_token_here
```

## FileRouter

```ts
// server/uploadthing.ts
import { createUploadthing, type FileRouter } from "uploadthing/server"
import { z } from "zod"

const f = createUploadthing()

export const uploadRouter = {
  imageUploader: f({
    image: { maxFileSize: "4MB", maxFileCount: 10 },
  })
    .input(z.object({ projectId: z.string() }))
    .middleware(async ({ input }) => {
      return { projectId: input.projectId }
    })
    .onUploadComplete(async ({ metadata, file }) => {
      await saveFileRecord(metadata.projectId, file.url, file.name)
      return { url: file.url }
    }),

  documentUploader: f({
    pdf: { maxFileSize: "16MB" },
    "application/msword": { maxFileSize: "16MB" },
  })
    .middleware(async () => {
      return {}
    })
    .onUploadComplete(async ({ file }) => {
      return { url: file.url }
    }),
} satisfies FileRouter

export type AppFileRouter = typeof uploadRouter
```

## Route Handler

```ts
// app/api/uploadthing/route.ts
import { createRouteHandler } from "uploadthing/next"
import { uploadRouter } from "@/server/uploadthing"

export const { GET, POST } = createRouteHandler({
  router: uploadRouter,
  config: {
    token: process.env.UPLOADTHING_TOKEN,
  },
})

export const runtime = "nodejs"
```

## Client Component

```tsx
"use client"

import { UploadButton, UploadDropzone } from "@uploadthing/react"
import type { AppFileRouter } from "@/server/uploadthing"

export const ImageUpload = ({ projectId }: { projectId: string }) => {
  return (
    <UploadDropzone<AppFileRouter, "imageUploader">
      endpoint="imageUploader"
      input={{ projectId }}
      onClientUploadComplete={(res) => {
        console.log("Upload complete:", res)
      }}
      onUploadError={(error) => {
        console.error("Upload failed:", error)
      }}
    />
  )
}
```

## Generate Components

```ts
// lib/uploadthing.ts
import { generateReactHelpers, generateUploadButton, generateUploadDropzone } from "@uploadthing/react"
import type { AppFileRouter } from "@/server/uploadthing"

export const UploadButton = generateUploadButton<AppFileRouter>()
export const UploadDropzone = generateUploadDropzone<AppFileRouter>()
export const { useUploadThing } = generateReactHelpers<AppFileRouter>()
```

## NEVER
- ❌ Use `UPLOADTHING_SECRET` (v6 pattern — use `UPLOADTHING_TOKEN`)
- ❌ Use Server Actions for file uploads (use `createRouteHandler`)
- ❌ Use edge runtime for the upload route (use `nodejs`)
- ❌ Skip file type or size validation in the FileRouter
- ❌ Store upload tokens in client-side code
