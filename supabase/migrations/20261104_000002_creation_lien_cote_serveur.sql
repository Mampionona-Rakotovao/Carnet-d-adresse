-- Migration : création des liens de partage côté serveur.
--
-- L'application n'envoie plus de date d'expiration : elle transmet une durée
-- en minutes (NULL = jamais). La base calcule `expires_at` avec son propre
-- `now()`, valide la durée et force `created_by = auth.uid()`.
--
-- La création directe dans `share_links` est révoquée pour les rôles clients :
-- seule la RPC `create_share_link` peut créer un lien. Les liens existants ne
-- sont pas modifiés.

BEGIN;

CREATE OR REPLACE FUNCTION public.create_share_link(
  p_address_id uuid,
  p_max_uses integer DEFAULT 1,
  p_duration_minutes integer DEFAULT 1440
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_link    public.share_links%rowtype;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'auth_required');
  END IF;

  IF p_duration_minutes IS NOT NULL
     AND (p_duration_minutes <= 0 OR p_duration_minutes > 525600) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_duration');
  END IF;

  IF p_max_uses IS NOT NULL AND p_max_uses <= 0 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_max_uses');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.addresses
    WHERE id = p_address_id
      AND owner_id = v_user_id
  ) THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;

  INSERT INTO public.share_links (
    address_id,
    created_by,
    status,
    expires_at,
    max_uses
  )
  VALUES (
    p_address_id,
    v_user_id,
    'ACTIVE',
    CASE
      WHEN p_duration_minutes IS NULL THEN NULL
      ELSE now() + make_interval(mins => p_duration_minutes)
    END,
    p_max_uses
  )
  RETURNING * INTO v_link;

  RETURN jsonb_build_object(
    'ok', true,
    'link', to_jsonb(v_link)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.create_share_link(uuid, integer, integer)
  FROM public;
GRANT EXECUTE ON FUNCTION public.create_share_link(uuid, integer, integer)
  TO authenticated;

-- Empêche un client de contourner le calcul de l'expiration par un INSERT
-- direct. La RPC SECURITY DEFINER continue de fonctionner.
REVOKE INSERT ON public.share_links FROM public, anon, authenticated;

COMMIT;
