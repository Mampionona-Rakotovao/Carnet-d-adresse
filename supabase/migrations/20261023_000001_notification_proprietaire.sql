-- Migration : notification du propriétaire à la connexion.
--
-- Jusqu'ici, seul le destinataire qui ouvrait le lien voyait un message.
-- Désormais, c'est le compte propriétaire du lien qui est notifié (message et
-- son) au moment où il se connecte, si des personnes ont ouvert ses liens
-- depuis sa dernière connexion. Le destinataire ne reçoit plus la notification
-- sonore.
--
-- Cette politique permet aussi au propriétaire de consulter l'historique des
-- accès de ses propres liens.

BEGIN;

DROP POLICY IF EXISTS share_link_uses_select_owner ON public.share_link_uses;
CREATE POLICY share_link_uses_select_owner
  ON public.share_link_uses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.share_links sl
      WHERE sl.id = share_link_uses.share_link_id
        AND sl.created_by = auth.uid()
    )
  );

COMMIT;
