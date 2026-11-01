-- Migration : consultation d'un lien partagé sans être connecté.
--
-- Le lien lui-même fait foi : tant que le jeton existe, est actif et n'a pas
-- expiré, un destinataire non connecté peut lire l'adresse en lecture seule.
-- On n'expose que des champs utiles à l'affichage : jamais owner_id, jamais le
-- contenu de la table share_links.

BEGIN;

-- 1) get_shared_address_full : accessible aux visiteurs anonymes, avec une
--    liste blanche de colonnes.
CREATE OR REPLACE FUNCTION public.get_shared_address_full(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_link       public.share_links%rowtype;
  v_addr       public.addresses%rowtype;
  v_landmarks  jsonb := '[]'::jsonb;
  v_steps      jsonb := '[]'::jsonb;
BEGIN
  SELECT *
    INTO v_link
  FROM public.share_links
  WHERE token = p_token
    AND status = 'ACTIVE'
    AND expires_at > now();

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

  RETURN jsonb_build_object(
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
    'steps', v_steps
  );
END;
$$;

-- 2) record_share_open : ne fait rien pour un visiteur anonyme (pas d'identité
--    à enregistrer), mais ne bloque pas l'affichage de l'adresse.
CREATE OR REPLACE FUNCTION public.record_share_open(p_token text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_link_id uuid;
  v_user_id uuid := auth.uid();
  v_created_by uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  SELECT id, created_by
    INTO v_link_id, v_created_by
  FROM public.share_links
  WHERE token = p_token
    AND status = 'ACTIVE'
    AND expires_at > now()
  FOR UPDATE;

  IF v_link_id IS NULL THEN
    RETURN;
  END IF;

  -- Ne pas enregistrer si le propriétaire ouvre son propre lien
  IF v_created_by = v_user_id THEN
    RETURN;
  END IF;

  INSERT INTO public.share_link_uses (share_link_id, used_by)
  VALUES (v_link_id, v_user_id)
  ON CONFLICT (share_link_id, used_by) DO NOTHING;
END;
$$;

-- 3) Permissions
REVOKE ALL ON FUNCTION public.get_shared_address_full(text) FROM public;
GRANT EXECUTE ON FUNCTION public.get_shared_address_full(text)
  TO anon, authenticated;

REVOKE ALL ON FUNCTION public.record_share_open(text) FROM public;
GRANT EXECUTE ON FUNCTION public.record_share_open(text) TO authenticated;

COMMIT;
