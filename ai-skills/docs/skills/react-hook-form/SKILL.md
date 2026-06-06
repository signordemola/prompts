---
name: react-hook-form
description: >
  Form handling with React Hook Form and Zod. ACTIVATE when: building forms,
  adding validation, creating multi-step wizards, or handling dynamic field
  arrays. Covers useForm, useWatch, useFieldArray, and Zod resolver.
---

# React Hook Form Skill

## When to Use
- Building any form (login, signup, booking, settings)
- Adding client-side validation with Zod
- Creating multi-step form wizards
- Handling dynamic field lists (add/remove items)

## Always Load First
- `skills/input-validation/SKILL.md`
- `skills/code-style/SKILL.md`

## Basic Form with Zod

```tsx
"use client"

import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

const FormSchema = z.object({
  name: z.string().trim().min(1, "Required"),
  email: z.email("Invalid email"),
})

type FormValues = z.infer<typeof FormSchema>

export const ContactForm = () => {
  const form = useForm<FormValues>({
    resolver: zodResolver(FormSchema),
    defaultValues: { name: "", email: "" },
  })

  const onSubmit = async (data: FormValues) => {
    await createContact(data)
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <input {...form.register("name")} placeholder="Name" />
      {form.formState.errors.name && (
        <span>{form.formState.errors.name.message}</span>
      )}

      <input {...form.register("email")} placeholder="Email" />
      {form.formState.errors.email && (
        <span>{form.formState.errors.email.message}</span>
      )}

      <button disabled={form.formState.isSubmitting}>Submit</button>
    </form>
  )
}
```

## useWatch (React 19)

Use `useWatch` instead of `watch` for better re-render performance:

```tsx
import { useWatch } from "react-hook-form"

const PricePreview = ({ control }: { control: Control<FormValues> }) => {
  const price = useWatch({ control, name: "price" })

  return <span>Total: £{(price / 100).toFixed(2)}</span>
}
```

## Multi-Step Form

```tsx
"use client"

import { useState } from "react"
import { FormProvider, useForm, useFormContext } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"

const WizardSchema = z.object({
  name: z.string().trim().min(1),
  email: z.email(),
  service: z.string().min(1),
  date: z.string().min(1),
  notes: z.string().optional(),
})

type WizardValues = z.infer<typeof WizardSchema>

export const BookingWizard = () => {
  const [step, setStep] = useState(0)
  const methods = useForm<WizardValues>({
    resolver: zodResolver(WizardSchema),
    defaultValues: { name: "", email: "", service: "", date: "", notes: "" },
    mode: "onTouched",
  })

  const steps = [StepContact, StepService, StepConfirm]
  const CurrentStep = steps[step]

  const onSubmit = async (data: WizardValues) => {
    await createBooking(data)
  }

  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(onSubmit)}>
        <CurrentStep />
        <div>
          {step > 0 && <button type="button" onClick={() => setStep(step - 1)}>Back</button>}
          {step < steps.length - 1 && (
            <button type="button" onClick={() => setStep(step + 1)}>Next</button>
          )}
          {step === steps.length - 1 && (
            <button disabled={methods.formState.isSubmitting}>Confirm</button>
          )}
        </div>
      </form>
    </FormProvider>
  )
}

const StepContact = () => {
  const { register, formState } = useFormContext<WizardValues>()
  return (
    <div>
      <input {...register("name")} placeholder="Name" />
      <input {...register("email")} placeholder="Email" />
    </div>
  )
}
```

## Dynamic Field Arrays

```tsx
import { useFieldArray, useForm } from "react-hook-form"

const LineItemsForm = () => {
  const form = useForm({
    defaultValues: { items: [{ description: "", amount: 0 }] },
  })

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: "items",
  })

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {fields.map((field, index) => (
        <div key={field.id}>
          <input {...form.register(`items.${index}.description`)} />
          <input {...form.register(`items.${index}.amount`, { valueAsNumber: true })} type="number" />
          <button type="button" onClick={() => remove(index)}>Remove</button>
        </div>
      ))}
      <button type="button" onClick={() => append({ description: "", amount: 0 })}>
        Add Item
      </button>
      <button>Save</button>
    </form>
  )
}
```

## With Server Actions

```tsx
const onSubmit = async (data: FormValues) => {
  const result = await serverAction(data)

  if (result.error) {
    form.setError("root", { message: result.error })
    return
  }
}
```

## NEVER
- ❌ Use `watch` (use `useWatch` for React 19 performance)
- ❌ Skip server-side validation (client validation is UX only)
- ❌ Use uncontrolled inputs without `register`
- ❌ Forget `defaultValues` (causes hydration mismatches in Next.js)
- ❌ Put validation logic in the component (use Zod schemas)
