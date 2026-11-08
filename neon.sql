-- Ethan Cloud database schema for Neon PostgreSQL.
-- Run on the Ethan Cloud project's main branch after Managed Better Auth is provisioned.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.cloud_folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL DEFAULT auth.uid(),
  name text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 120),
  parent_id uuid NULL,
  is_starred boolean NOT NULL DEFAULT false,
  is_trashed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cloud_folders_id_owner_unique UNIQUE (id, owner_id),
  CONSTRAINT cloud_folders_parent_owner_fk
    FOREIGN KEY (parent_id, owner_id)
    REFERENCES public.cloud_folders(id, owner_id)
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.cloud_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL DEFAULT auth.uid(),
  folder_id uuid NULL,
  name text NOT NULL,
  storage_path text NOT NULL UNIQUE,
  mime_type text NULL,
  size_bytes bigint NOT NULL DEFAULT 0 CHECK (size_bytes >= 0),
  is_starred boolean NOT NULL DEFAULT false,
  is_trashed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cloud_files_folder_owner_fk
    FOREIGN KEY (folder_id, owner_id)
    REFERENCES public.cloud_folders(id, owner_id)
    ON DELETE SET NULL (folder_id)
);

CREATE INDEX IF NOT EXISTS cloud_folders_owner_parent_idx ON public.cloud_folders(owner_id, parent_id);
CREATE INDEX IF NOT EXISTS cloud_files_owner_created_idx ON public.cloud_files(owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS cloud_files_owner_folder_idx ON public.cloud_files(owner_id, folder_id);
CREATE INDEX IF NOT EXISTS cloud_files_owner_starred_idx ON public.cloud_files(owner_id, is_starred) WHERE is_starred = true;

ALTER TABLE public.cloud_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cloud_files ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cloud_folders_select_own ON public.cloud_folders;
CREATE POLICY cloud_folders_select_own ON public.cloud_folders FOR SELECT TO authenticated USING (owner_id = auth.uid());
DROP POLICY IF EXISTS cloud_folders_insert_own ON public.cloud_folders;
CREATE POLICY cloud_folders_insert_own ON public.cloud_folders FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS cloud_folders_update_own ON public.cloud_folders;
CREATE POLICY cloud_folders_update_own ON public.cloud_folders FOR UPDATE TO authenticated USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS cloud_folders_delete_own ON public.cloud_folders;
CREATE POLICY cloud_folders_delete_own ON public.cloud_folders FOR DELETE TO authenticated USING (owner_id = auth.uid());

DROP POLICY IF EXISTS cloud_files_select_own ON public.cloud_files;
CREATE POLICY cloud_files_select_own ON public.cloud_files FOR SELECT TO authenticated USING (owner_id = auth.uid());
DROP POLICY IF EXISTS cloud_files_insert_own ON public.cloud_files;
CREATE POLICY cloud_files_insert_own ON public.cloud_files FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS cloud_files_update_own ON public.cloud_files;
CREATE POLICY cloud_files_update_own ON public.cloud_files FOR UPDATE TO authenticated USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS cloud_files_delete_own ON public.cloud_files;
CREATE POLICY cloud_files_delete_own ON public.cloud_files FOR DELETE TO authenticated USING (owner_id = auth.uid());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.cloud_folders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cloud_files TO authenticated;
