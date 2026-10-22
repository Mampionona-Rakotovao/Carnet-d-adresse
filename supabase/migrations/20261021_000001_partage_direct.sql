-- Migration : partage direct "Partagées avec moi"
-- Adapté au schéma existant (share_link_uses.used_by)

BEGIN;

-- 1) S'assurer que la table existe avec les bonnes colonnes
CREATE TABLE IF NOT EXISTS public.share_link_uses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  share_link_id uuid NOT NULL REFERENCES public.share_links(id) ON DELETE CASCADE,
  used_by uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  used_at timestamptz NOT NULL DEFAULT now()
);

-- Si la table existait déjà avec une autre colonne, on essaie d'aligner
DO $$
BEGIN
  -- Ajouter used_by s'il manque
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='share_link_uses' AND column_name='used_by'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema='public' AND table_name='share_link_uses' AND column_name='user_id'
  ) THEN
    ALTER TABLE public.share_link_uses ADD COLUMN used_by uuid REFERENCES auth.users(id) ON DELETE CASCADE;
    UPDATE public.share_link_uses SET used_by = user_id WHERE used_by IS NULL;
    ALTER TABLE public.share_link_uses DROP COLUMN user_id;
  END IF;
  
  -- Si used_by existe mais pas user_id, c'est OK
END $$;

-- 2) Nettoyer les doublons existants avant d'imposer l'unicité (sur used_by)
DO $$
BEGIN
  WITH dups AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY share_link_id, used_by ORDER BY used_at ASC, id ASC) AS rn
    FROM public.share_link_uses
    WHERE used_by IS NOT NULL
  )
  DELETE FROM public.share_link_uses s
  USING dups d
  WHERE s.id = d.id AND d.rn > 1;
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- 3) Index / contrainte d'unicité
CREATE UNIQUE INDEX IF NOT EXISTS idx_share_link_uses_unique
  ON public.share_link_uses (share_link_id, used_by);

CREATE INDEX IF NOT EXISTS idx_share_link_uses_link_id ON public.share_link_uses (share_link_id);
CREATE INDEX IF NOT EXISTS idx_share_link_uses_user_id ON public.share_link_uses (used_by);

-- 4) record_share_open
CREATE OR REPLACE FUNCTION public.record_share_open(p_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_link_id uuid;
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  SELECT id
    INTO v_link_id
  FROM public.share_links
  WHERE token = p_token
    AND status = 'ACTIVE'
    AND expires_at > now()
  FOR UPDATE;

  IF v_link_id IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.share_link_uses (share_link_id, used_by)
  VALUES (v_link_id, v_user_id)
  ON CONFLICT (share_link_id, used_by) DO NOTHING;
END;
$$;

-- 5) get_my_shared_addresses
CREATE OR REPLACE FUNCTION public.get_my_shared_addresses()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  result jsonb := '[]'::jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN result;
  END IF;

  SELECT jsonb_agg(
           jsonb_build_object(
             'token', sl.token,
             'expires_at', sl.expires_at,
             'address', jsonb_build_object(
               'id', a.id,
               'name', a.name,
               'locality', a.locality,
               'description', a.description,
               'latitude', a.latitude,
               'longitude', a.longitude,
               'gps_type', a.gps_type,
               'photo_url', a.photo_url,
               'visibility', a.visibility
             ),
             'shared_by', jsonb_build_object(
               'id', p.id,
               'name', p.name,
               'email', p.email
             ),
             'owner_name', p.name
           )
           ORDER BY slu.used_at DESC
         )
    INTO result
  FROM public.share_link_uses slu
  JOIN public.share_links sl ON sl.id = slu.share_link_id
  JOIN public.addresses a   ON a.id  = sl.address_id
  LEFT JOIN public.profiles p ON p.id = sl.created_by
  WHERE slu.used_by = v_user_id
    AND sl.status    = 'ACTIVE'
    AND sl.expires_at > now();

  RETURN COALESCE(result, '[]'::jsonb);
END;
$$;

-- 6) get_shared_address_full
CREATE OR REPLACE FUNCTION public.get_shared_address_full(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id    uuid := auth.uid();
  v_link       public.share_links%rowtype;
  v_addr       public.addresses%rowtype;
  v_landmarks  jsonb := '[]'::jsonb;
  v_steps      jsonb := '[]'::jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentification requise pour consulter un lien partagé.';
  END IF;

  SELECT *
    INTO v_link
  FROM public.share_links
  WHERE token = p_token
    AND status = 'ACTIVE'
    AND expires_at > now()
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT *
    INTO v_addr
  FROM public.addresses
  WHERE id = v_link.address_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT COALESCE(jsonb_agg(to_jsonb(l) ORDER BY l.position_order, l.created_at), '[]'::jsonb)
    INTO v_landmarks
  FROM public.landmarks l
  WHERE l.address_id = v_addr.id;

  SELECT COALESCE(jsonb_agg(to_jsonb(s) ORDER BY s.step_order), '[]'::jsonb)
    INTO v_steps
  FROM public.route_steps s
  WHERE s.address_id = v_addr.id;

  RETURN jsonb_build_object(
    'address',    to_jsonb(v_addr),
    'landmarks',  v_landmarks,
    'steps',      v_steps
  );
END;
$$;

-- 7) Nettoyage ancien nom
DROP FUNCTION IF EXISTS public.list_shared_with_me();

-- 8) Permissions
REVOKE ALL ON FUNCTION public.record_share_open(text) FROM public;
GRANT EXECUTE ON FUNCTION public.record_share_open(text) TO authenticated;

REVOKE ALL ON FUNCTION public.get_my_shared_addresses() FROM public;
GRANT EXECUTE ON FUNCTION public.get_my_shared_addresses() TO authenticated;

REVOKE ALL ON FUNCTION public.get_shared_address_full(text) FROM public;
GRANT EXECUTE ON FUNCTION public.get_shared_address_full(text) TO authenticated;

-- 9) RLS
ALTER TABLE public.share_link_uses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS share_link_uses_insert_own ON public.share_link_uses;
CREATE POLICY share_link_uses_insert_own
  ON public.share_link_uses
  FOR INSERT
  TO authenticated
  WITH CHECK (used_by = auth.uid());

DROP POLICY IF EXISTS share_link_uses_select_own ON public.share_link_uses;
CREATE POLICY share_link_uses_select_own
  ON public.share_link_uses
  FOR SELECT
  TO authenticated
  USING (used_by = auth.uid());

COMMIT;
