# Ethan Cloud v9 — Ethan ID Connected

This build moves Ethan Cloud authentication, database metadata, and private Storage authorization to the NEW ETHAN ID Supabase project.

## Supabase project
Project URL is already configured in config.js with the frontend-safe publishable key.

## Before deploying
1. Open the NEW ETHAN ID Supabase project.
2. SQL Editor -> New query -> paste and run `supabase.sql` once.
3. Authentication -> URL Configuration:
   - Keep Hub as Site URL if already configured.
   - Add `https://cloud.ethandigitalacademy.org/**` to Redirect URLs.
4. Deploy these files to the existing Ethan Cloud GitHub/Vercel project.

## Important identity note
Hub and Cloud now use the same Ethan ID user directory. That means the same Ethan ID credentials/user UUID can secure Cloud files. Browser sessions are origin-scoped, however, so this build does not falsely pass access/refresh tokens through URLs. A user may still be asked to authenticate on Cloud until a dedicated secure cross-domain SSO exchange is added.

## Old Cloud project
Do not delete the old Cloud Supabase project yet. Existing files/data are not automatically migrated by this package.
