const createSubscriptionSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100, 'Name must not exceed 100 characters'),
  description: z.string().max(500, 'Description must not exceed 500 characters').optional(),
  price: z.number().min(0, 'Price must be non-negative').max(1_000_000, 'Price exceeds maximum allowed value'),
  billing_cycle: z.enum(['monthly', 'yearly', 'quarterly']),

  // ✅ keep BOTH fields (this is the correct merge)
  category: z.string().max(50, 'Category must not exceed 50 characters').optional(),

  currency: z.string()
    .refine(
      (val) => (SUPPORTED_CURRENCIES as readonly string[]).includes(val),
      { message: `Currency must be one of: ${SUPPORTED_CURRENCIES.join(', ')}` }
    )
    .optional(),

  renewal_url: safeUrlSchema.optional(),
  website_url: safeUrlSchema.optional(),
  logo_url: safeUrlSchema.optional(),
  notes: z.string().max(1000, 'Notes must not exceed 1000 characters').optional(),
});