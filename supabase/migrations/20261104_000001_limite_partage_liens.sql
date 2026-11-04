-- Migration : limite du nombre de personnes par lien de partage.
--
-- Principes :
-- - `max_uses` NULL = nombre illimité (compatibilité avec les anciens liens).
-- - `expires_at` NULL = lien sans expiration (compatibilité avec les anciens
--   liens, et choix « Jamais » dans l'application).
-- - `share_link_redemptions` est la source de vérité pour compter les places.
--   `share_link_uses` reste alimentée pour l'historique et les notifications.
-- - La consommation d'une place se fait uniquement dans `redeem_share_link`,
--   sous verrou, et jamais depuis le client.
-- - Les anciennes RPC `get_shared_address_full` et `record_share_open` sont
--   désactivées : elles permettraient de contourner la limite.

BEGIN;

-- 1) Colonnes de configuration du lien -------------------------------------
ALTER TABLE public.share_links
  ADD COLUMN IF NOT EXISTS max_uses integer;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'share_links_max_uses_check'
      AND conrelid = 'public.share_links'::regclass
  ) THEN
    ALTER TABLE public.share_links
      ADD CONSTRAINT share_links_max_uses_check
      CHECK (max_uses IS NULL OR max_uses > 0);
  END IF;
END $$;

-- Les liens « Jamais » n'ont plus de date d'expiration.
ALTER TABLE public.share_links
  ALTER COLUMN expires_at DROP NOT NULL;

-- 2) Table autoritaire des places consommées -------------------------------
CREATE TABLE IF NOT EXISTS public.share_link_redemptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  share_link_id uuid NOT NULL
    REFERENCES public.share_links(id) ON DELETE CASCADE,
  user_id uuid NOT NULL
    REFERENCES auth.users(id) ON DELETE CASCADE,
  redeemed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (share_link_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_share_link_redemptions_link_id
  ON public.share_link_redemptions (share_link_id);

CREATE INDEX IF NOT EXISTS idx_share_link_redemptions_user_id
  ON public.share_link_redemptions (user_id);

-- Reprendre les ouvertures déjà enregistrées par l'ancien système.
INSERT INTO public.share_link_redemptions (share_link_id, user_id, redeemed_at)
SELECT slu.share_link_id, slu.used_by, slu.used_at
FROM public.share_link_uses slu
WHERE slu.used_by IS NOT NULL
ON CONFLICT (share_link_id, user_id) DO NOTHING;

-- 3) RLS des places consommées ---------------------------------------------
ALTER TABLE public.share_link_redemptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS share_link_redemptions_select_owner
  ON public.share_link_redemptions;
CREATE POLICY share_link_redemptions_select_owner
  ON public.share_link_redemptions
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.share_links sl
      WHERE sl.id = share_link_redemptions.share_link_id
        AND sl.created_by = auth.uid()
    )
  );

REVOKE ALL ON public.share_link_redemptions
  FROM public, anon, authenticated;
GRANT SELECT ON public.share_link_redemptions TO authenticated;

-- Les ouvertures ne doivent plus être insérées directement par le client :
-- seule la RPC `redeem_share_link` peut le faire, après contrôle de la limite.
DROP POLICY IF EXISTS share_link_uses_insert_own ON public.share_link_uses;
REVOKE INSERT ON public.share_link_uses
  FROM public, anon, authenticated;

-- 4) Consommer une place et retourner l'adresse ----------------------------
CREATE OR REPLACE FUNCTION public.redeem_share_link(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id       uuid := auth.uid();
  v_link          public.share_links%rowtype;
  v_addr          public.addresses%rowtype;
  v_landmarks     jsonb := '[]'::jsonb;
  v_steps         jsonb := '[]'::jsonb;
  v_used_count    integer := 0;
  v_already       boolean := false;
  v_is_owner      boolean := false;
  v_remaining     integer;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'auth_required');
  END IF;

  IF p_token IS NULL OR btrim(p_token) = '' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  -- Le verrou sérialise les demandes concurrentes sur le même lien : deux
  -- personnes ne peuvent pas consommer la dernière place en même temps.
  SELECT *
    INTO v_link
  FROM public.share_links
  WHERE token = p_token
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF v_link.status = 'REVOKED' OR v_link.revoked_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'revoked');
  END IF;

  IF v_link.status = 'EXPIRED' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'expired');
  END IF;

  IF v_link.status <> 'ACTIVE' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  IF v_link.expires_at IS NOT NULL AND v_link.expires_at <= now() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'expired');
  END IF;

  v_is_owner := v_link.created_by = v_user_id;

  SELECT count(*)
    INTO v_used_count
  FROM public.share_link_redemptions
  WHERE share_link_id = v_link.id;

  SELECT EXISTS (
    SELECT 1
    FROM public.share_link_redemptions
    WHERE share_link_id = v_link.id
      AND user_id = v_user_id
  )
    INTO v_already;

  -- Un compte déjà enregistré peut rouvrir le lien sans consommer de place.
  -- Le propriétaire peut toujours consulter son propre lien.
  IF NOT v_is_owner AND NOT v_already THEN
    IF v_link.max_uses IS NOT NULL
       AND v_used_count >= v_link.max_uses THEN
      RETURN jsonb_build_object('ok', false, 'error', 'full');
    END IF;

    INSERT INTO public.share_link_redemptions (share_link_id, user_id)
    VALUES (v_link.id, v_user_id)
    ON CONFLICT (share_link_id, user_id) DO NOTHING;

    -- Compatibilité avec « Partagées avec moi » et les notifications.
    INSERT INTO public.share_link_uses (share_link_id, used_by)
    VALUES (v_link.id, v_user_id)
    ON CONFLICT (share_link_id, used_by) DO NOTHING;

    v_used_count := v_used_count + 1;
  END IF;

  SELECT *
    INTO v_addr
  FROM public.addresses
  WHERE id = v_link.address_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  SELECT COALESCE(
           jsonb_agg(
             jsonb_build_object(
               'id', l.id,
               'address_id', l.address_id,
               'name', l.name,
               'description', l.description,
               'photo_url', l.photo_url,
               'latitude', l.latitude,
               'longitude', l.longitude,
               'position_order', l.position_order
             )
             ORDER BY l.position_order, l.created_at
           ),
           '[]'::jsonb
         )
    INTO v_landmarks
  FROM public.landmarks l
  WHERE l.address_id = v_addr.id;

  SELECT COALESCE(
           jsonb_agg(
             jsonb_build_object(
               'id', s.id,
               'address_id', s.address_id,
               'step_order', s.step_order,
               'instruction', s.instruction,
               'distance', s.distance,
               'direction', s.direction,
               'landmark_id', s.landmark_id
             )
             ORDER BY s.step_order
           ),
           '[]'::jsonb
         )
    INTO v_steps
  FROM public.route_steps s
  WHERE s.address_id = v_addr.id;

  v_remaining := CASE
    WHEN v_link.max_uses IS NULL THEN NULL
    ELSE greatest(v_link.max_uses - v_used_count, 0)
  END;

  RETURN jsonb_build_object(
    'ok', true,
    'address', jsonb_build_object(
      'id', v_addr.id,
      'name', v_addr.name,
      'description', v_addr.description,
      'locality', v_addr.locality,
      'latitude', v_addr.latitude,
      'longitude', v_addr.longitude,
      'gps_type', v_addr.gps_type,
      'photo_url', v_addr.photo_url,
      'visibility', v_addr.visibility,
      'created_at', v_addr.created_at
    ),
    'landmarks', v_landmarks,
    'steps', v_steps,
    'expires_at', v_link.expires_at,
    'max_uses', v_link.max_uses,
    'used_count', v_used_count,
    'remaining', v_remaining,
    'already_redeemed', v_already,
    'is_owner', v_is_owner
  );
END;
$$;

-- 5) Révocation réservée au propriétaire -----------------------------------
CREATE OR REPLACE FUNCTION public.revoke_share_link(p_link_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_id      uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'auth_required');
  END IF;

  UPDATE public.share_links
  SET status = 'REVOKED',
      revoked_at = COALESCE(revoked_at, now())
  WHERE id = p_link_id
    AND created_by = v_user_id
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  RETURN jsonb_build_object('ok', true);
END;
$$;

-- 6) « Partagées avec moi » : source = places réellement consommées --------
CREATE OR REPLACE FUNCTION public.get_my_shared_addresses()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  result    jsonb := '[]'::jsonb;
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
           ORDER BY slr.redeemed_at DESC
         )
    INTO result
  FROM public.share_link_redemptions slr
  JOIN public.share_links sl ON sl.id = slr.share_link_id
  JOIN public.addresses a    ON a.id  = sl.address_id
  LEFT JOIN public.profiles p ON p.id = sl.created_by
  WHERE slr.user_id = v_user_id
    AND sl.created_by != v_user_id
    AND sl.status = 'ACTIVE'
    AND sl.revoked_at IS NULL
    AND (sl.expires_at IS NULL OR sl.expires_at > now());

  RETURN COALESCE(result, '[]'::jsonb);
END;
$$;

-- 7) Permissions ------------------------------------------------------------
REVOKE ALL ON FUNCTION public.redeem_share_link(text) FROM public;
GRANT EXECUTE ON FUNCTION public.redeem_share_link(text) TO authenticated;

REVOKE ALL ON FUNCTION public.revoke_share_link(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.revoke_share_link(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.get_my_shared_addresses() FROM public;
GRANT EXECUTE ON FUNCTION public.get_my_shared_addresses() TO authenticated;

-- Anciennes RPC : plus exécutables, sinon la limite est contournable.
REVOKE ALL ON FUNCTION public.get_shared_address_full(text)
  FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.record_share_open(text)
  FROM public, anon, authenticated;

COMMIT;
