# Ethan Cloud v8 — Connected Workspace

This version turns Ethan Cloud into the central workspace for the Ethan ecosystem.

## Main improvements
- New compact Home dashboard explaining what Ethan Cloud is for.
- Quick actions: Upload, New Folder, Ethan Office, My Learning, Projects, Ethan AI.
- Ethan ecosystem launcher for Office, Learn, LMS/ERP and AI.
- Automatic private root folders: Ethan Office, Learning Materials, Assignments, Projects, Projects.
- Existing My Files, Recent, Starred, Trash, upload, folders, rename, restore and private signed-file access retained.
- Responsive, smaller typography and denser layout so more content is visible.

## Deployment
Keep your existing Supabase project and run supabase.sql only if the database policies/tables were not previously installed. Keep config.js with your current Supabase URL/publishable key. Upload these files to the existing Ethan Cloud GitHub repository and redeploy on Vercel.
