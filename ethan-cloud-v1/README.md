# Ethan Cloud v6
Responsive Ethan Cloud interface with Supabase authentication, private storage, folders, uploads, file search, recent/starred/trash views, rename, restore, permanent delete and password recovery.

## Deploy
1. Keep `config.js` configured for the Ethan Cloud Supabase project.
2. Ensure `supabase.sql` has already been run.
3. Upload these files to the GitHub repository root.
4. Vercel can deploy as a static project with Framework Preset: Other.
5. In Supabase Authentication > URL Configuration, set Site URL to the production URL and add the production URL to Redirect URLs.
