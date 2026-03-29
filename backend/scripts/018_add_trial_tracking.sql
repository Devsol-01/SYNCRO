-- Add trial tracking columns to subscriptions table
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS is_trial BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS trial_converts_to_price DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS credit_card_required BOOLEAN DEFAULT FALSE;

-- Index for efficient trial expiry queries
CREATE INDEX IF NOT EXISTS subscriptions_trial_ends_at_idx
  ON public.subscriptions(trial_ends_at)
  WHERE is_trial = TRUE;

-- Table to track trial conversion events
CREATE TABLE IF NOT EXISTS public.trial_conversion_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversion_type TEXT NOT NULL CHECK (conversion_type IN ('intentional', 'automatic', 'cancelled')),
  -- intentional = user clicked "Keep", automatic = auto-charged, cancelled = user cancelled before charge
  reminder_count INTEGER DEFAULT 0,       -- how many trial reminders were sent
  acted_on_reminder BOOLEAN DEFAULT FALSE, -- did user act after receiving a reminder?
  saved_by_syncro BOOLEAN DEFAULT FALSE,   -- trial cancelled before auto-charge thanks to SYNCRO reminder
  converted_price DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.trial_conversion_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "trial_conversion_events_select_own"
  ON public.trial_conversion_events FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "trial_conversion_events_insert_own"
  ON public.trial_conversion_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS trial_conversion_events_user_id_idx ON public.trial_conversion_events(user_id);
CREATE INDEX IF NOT EXISTS trial_conversion_events_subscription_id_idx ON public.trial_conversion_events(subscription_id);
CREATE INDEX IF NOT EXISTS trial_conversion_events_saved_by_syncro_idx ON public.trial_conversion_events(saved_by_syncro) WHERE saved_by_syncro = TRUE;
