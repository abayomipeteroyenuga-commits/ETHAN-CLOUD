# Ethan Cloud — Neon backend

Ethan Cloud now runs on its own Neon project and no longer uses Ethan ID, Supabase Auth, or another Ethan app's identity service.

## Backend

- Neon project: `ETHAN CLOUD`
- Database: `ethancloud` (PostgreSQL 17)
- Authentication: Neon Managed Better Auth (email/password)
- Database API: Neon Data API with JWT verification and PostgreSQL row-level security
- Object storage: private Neon bucket `ethan-cloud-files`
- Production application: https://cloud.ethandigitalacademy.org

## Data security

The `cloud_files` and `cloud_folders` tables are protected by owner-scoped RLS. Each signed-in user's ID is applied as the row owner. File access is scoped to a storage key beginning with that user's own ID.

Storage secrets are only stored as encrypted Vercel environment variables and are used by `api/storage/presign.js`. The browser receives short-lived presigned URLs, never the S3 credentials.

## Vercel environment variables

The Vercel project needs these values for Production, Preview, and Development:

- `NEON_AUTH_JWKS_URL`
- `AWS_ENDPOINT_URL_S3`
- `AWS_REGION`
- `AWS_ACCESS_KEY_ID` (encrypted)
- `AWS_SECRET_ACCESS_KEY` (encrypted)
- `NEON_STORAGE_BUCKET`

Public Neon Auth and Data API URLs are configured in `config.js`.

## Account and file migration notes

Ethan Cloud now uses a separate Neon identity directory. Existing accounts from the former Supabase project cannot be imported with their old password hashes; users must register a new Ethan Cloud account. Existing file metadata and stored objects are not automatically copied from the former storage backend. Keep that previous project available until any required data export or migration has been completed.

## Local development

Use the production Neon configuration only in a secure local environment. For storage operations, provide the server-side environment values listed above. Never expose the S3 access key or secret in browser JavaScript.
