# ETHAN CLOUD v2 — Supabase Ready

## Included
- Email/password authentication
- Private per-user file storage
- Upload and signed file opening/download
- Folders
- Search
- Recent, Starred and Trash views
- Restore and permanent delete
- Storage usage display
- PostgreSQL metadata with Row Level Security
- Private Supabase Storage bucket policies

## Setup
1. Create/open a Supabase project.
2. Open SQL Editor and run `supabase.sql` once.
3. Open `config.js` and replace the two placeholders with your Supabase Project URL and publishable/anon key. Never put the service-role key in this file.
4. In Supabase Authentication, configure your production Site URL as `https://cloud.ethandigitalacademy.org` when the domain is live.
5. Upload these files to GitHub and deploy to Vercel.
6. Connect `cloud.ethandigitalacademy.org` in Vercel and add the DNS record Vercel provides.

Security note: the bucket is private and policies restrict object paths to the signed-in user's user ID.
