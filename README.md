# ETHAN CLOUD v7

Auth, UI/UX and security-focused update.

- Repaired email/password account creation flow.
- Removed localhost/current-origin dependency from sign-up/reset requests.
- Added loading states and clearer authentication errors.
- Reduced typography, spacing, cards, sidebar and login dimensions.
- Retains private Supabase Storage and RLS policies.

In Supabase Authentication > URL Configuration, set Site URL to the live Vercel URL, then later to https://cloud.ethandigitalacademy.org. Keep Email provider enabled. Never expose service_role keys or database passwords in frontend files.
