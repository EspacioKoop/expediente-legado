"""Pruebas para publicar_acciones, liberar_por_pr y recuperar_prs_cerradas en gestionar_reservas.py."""

from datetime import datetime, timezone
import unittest
from unittest.mock import patch

import gestionar_reservas as gr

T0 = datetime(2026, 10, 17, 12, 0, tzinfo=timezone.utc)


def crear_reserva(
    issue=10,
    agent="agent-a",
    branch="feature/10-a",
    files="a.py",
    goal="goal",
    claimed_at=T0,
    last_activity=T0,
    lease_hours=2,
    pr=None,
    released=False,
):
    return gr.Reserva(
        issue=issue,
        agent=agent,
        branch=branch,
        files=files,
        goal=goal,
        claimed_at=claimed_at,
        last_activity=last_activity,
        lease_hours=lease_hours,
        pr=pr,
        released=released,
    )


class PublicarAccionesTest(unittest.TestCase):
    @patch("gestionar_reservas.api_json")
    def test_publicar_acciones_dry_run(self, mock_api_json):
        mock_api_json.return_value = ({"labels": []}, {})
        reserva1 = crear_reserva(issue=1, branch="feature/1-a")
        reserva2 = crear_reserva(issue=2, branch="feature/2-b")
        acciones = [
            (reserva1, "reserva-caducada", None),
            (
                reserva2,
                "merge-detectado-automaticamente",
                {"number": 100, "merged_at": "2026-10-17T11:00:00Z", "merge_commit_sha": "abc"},
            ),
        ]

        fallos = gr.publicar_acciones(acciones, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertTrue(reserva1.released)
        self.assertTrue(reserva2.released)
        for call in mock_api_json.call_args_list:
            self.assertNotEqual(call.args[0], "POST")

    @patch("gestionar_reservas.api_json")
    def test_publicar_acciones_continua_ante_fallos(self, mock_api_json):
        def api_side_effect(method, path, payload=None, dormir=None):
            if path == f"/repos/{gr.REPO}/issues/{gr.REGISTRO_ISSUE}/comments":
                if payload and "issue=#1" in payload.get("body", ""):
                    raise RuntimeError("Error simulado de red en issue 1")
            return ({"labels": []}, {})

        mock_api_json.side_effect = api_side_effect
        reserva1 = crear_reserva(issue=1, branch="feature/1-a")
        reserva2 = crear_reserva(issue=2, branch="feature/2-b")
        acciones = [
            (reserva1, "reserva-caducada", None),
            (reserva2, "reserva-caducada", None),
        ]

        fallos = gr.publicar_acciones(acciones, dry_run=False)

        self.assertEqual(fallos, 1)
        self.assertFalse(reserva1.released)
        self.assertTrue(reserva2.released)

    @patch("gestionar_reservas.api_json")
    def test_publicar_acciones_limpia_labels_si_merge_automatico(self, mock_api_json):
        def api_side_effect(method, path, payload=None, dormir=None):
            if method == "GET" and path == f"/repos/{gr.REPO}/issues/10":
                return ({"labels": [{"name": "agent:auto"}, {"name": "bug"}]}, {})
            return (None, {})

        mock_api_json.side_effect = api_side_effect
        reserva = crear_reserva(issue=10, branch="feature/10-a")
        pr_info = {"number": 50, "merged_at": "2026-10-17T11:00:00Z", "merge_commit_sha": "123"}
        acciones = [(reserva, "merge-detectado-automaticamente", pr_info)]

        fallos = gr.publicar_acciones(acciones, dry_run=False)

        self.assertEqual(fallos, 0)
        self.assertTrue(reserva.released)

    @patch("gestionar_reservas.api_json")
    def test_publicar_acciones_captura_error_limpiar_labels(self, mock_api_json):
        def api_side_effect(method, path, payload=None, dormir=None):
            if method == "GET" and "issues/10" in path:
                raise RuntimeError("No se pudieron consultar las labels")
            return (None, {})

        mock_api_json.side_effect = api_side_effect
        reserva = crear_reserva(issue=10, branch="feature/10-a")
        acciones = [(reserva, "merge-detectado-automaticamente", None)]

        fallos = gr.publicar_acciones(acciones, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertTrue(reserva.released)


class LiberarPorPrTest(unittest.TestCase):
    @patch("gestionar_reservas.obtener_pr")
    def test_pr_no_cerrado_no_libera_nada(self, mock_obtener_pr):
        mock_obtener_pr.return_value = {"number": 12, "state": "open"}
        reserva = crear_reserva(issue=10, pr=12)
        reservas = {(10, reserva.branch): reserva}

        resultado = gr.liberar_por_pr(reservas, numero_pr=12, dry_run=True)

        self.assertEqual(resultado, 0)
        self.assertFalse(reserva.released)

    @patch("gestionar_reservas.api_json")
    @patch("gestionar_reservas.obtener_pr")
    def test_pr_cerrado_con_merge_libera_reserva_por_numero_o_rama(
        self, mock_obtener_pr, mock_api_json
    ):
        mock_api_json.return_value = ({"labels": []}, {})
        mock_obtener_pr.return_value = {
            "number": 12,
            "state": "closed",
            "merged_at": "2026-10-17T11:00:00Z",
            "merge_commit_sha": "abc1234",
            "head": {"ref": "feature/branch-matching"},
        }
        res1 = crear_reserva(issue=1, pr=12, branch="feature/other")
        res2 = crear_reserva(issue=2, pr=None, branch="feature/branch-matching")
        res3 = crear_reserva(issue=3, pr=99, branch="feature/unrelated")
        reservas = {
            (1, res1.branch): res1,
            (2, res2.branch): res2,
            (3, res3.branch): res3,
        }

        fallos = gr.liberar_por_pr(reservas, numero_pr=12, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertTrue(res1.released)
        self.assertTrue(res2.released)
        self.assertFalse(res3.released)

    @patch("gestionar_reservas.api_json")
    @patch("gestionar_reservas.obtener_pr")
    def test_pr_cerrado_sin_merge_usa_motivo_pr_cerrado_sin_integrar(
        self, mock_obtener_pr, mock_api_json
    ):
        mock_api_json.return_value = ({"labels": []}, {})
        mock_obtener_pr.return_value = {
            "number": 14,
            "state": "closed",
            "merged_at": None,
            "head": {"ref": "feature/branch-closed"},
        }
        res = crear_reserva(issue=14, pr=14, branch="feature/branch-closed")
        reservas = {(14, res.branch): res}

        with patch("gestionar_reservas.publicar_acciones") as mock_publicar:
            mock_publicar.return_value = 0
            gr.liberar_por_pr(reservas, numero_pr=14, dry_run=True)
            mock_publicar.assert_called_once()
            acciones = mock_publicar.call_args[0][0]
            self.assertEqual(acciones[0][1], "PR-cerrado-sin-integrar")

    @patch("gestionar_reservas.obtener_pr")
    def test_sin_reservas_coincidentes_retorna_0(self, mock_obtener_pr):
        mock_obtener_pr.return_value = {
            "number": 50,
            "state": "closed",
            "head": {"ref": "feature/none"},
        }
        res = crear_reserva(issue=1, pr=10, branch="feature/other")
        reservas = {(1, res.branch): res}

        resultado = gr.liberar_por_pr(reservas, numero_pr=50, dry_run=True)

        self.assertEqual(resultado, 0)
        self.assertFalse(res.released)


class RecuperarPrsCerradasTest(unittest.TestCase):
    @patch("gestionar_reservas.api_json")
    @patch("gestionar_reservas.obtener_pr")
    def test_recuperar_prs_cerradas_con_pr_asociado(self, mock_obtener_pr, mock_api_json):
        mock_api_json.return_value = ({"labels": []}, {})
        mock_obtener_pr.return_value = {
            "number": 50,
            "state": "closed",
            "merged_at": "2026-10-17T11:00:00Z",
            "merge_commit_sha": "abc",
        }
        res = crear_reserva(issue=1, pr=50, branch="feature/50")
        reservas = {(1, res.branch): res}

        fallos = gr.recuperar_prs_cerradas(reservas, ahora=T0, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertTrue(res.released)

    @patch("gestionar_reservas.api_json")
    @patch("gestionar_reservas.obtener_pr_cerrada_de_rama")
    def test_recuperar_prs_cerradas_sin_pr_asociado_pero_rama_cerrada_posterior_a_claim(
        self, mock_pr_cerrada_rama, mock_api_json
    ):
        mock_api_json.return_value = ({"labels": []}, {})
        mock_pr_cerrada_rama.return_value = {
            "number": 60,
            "state": "closed",
            "closed_at": "2026-10-17T13:00:00Z",
            "merged_at": "2026-10-17T13:00:00Z",
            "merge_commit_sha": "def",
        }
        res = crear_reserva(issue=2, pr=None, branch="feature/60", claimed_at=T0)
        reservas = {(2, res.branch): res}

        fallos = gr.recuperar_prs_cerradas(reservas, ahora=T0, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertTrue(res.released)

    @patch("gestionar_reservas.obtener_pr_cerrada_de_rama")
    def test_recuperar_prs_cerradas_ignora_pr_cerrada_anterior_a_claim(
        self, mock_pr_cerrada_rama
    ):
        mock_pr_cerrada_rama.return_value = {
            "number": 60,
            "state": "closed",
            "closed_at": "2026-10-17T11:00:00Z",
            "merged_at": "2026-10-17T11:00:00Z",
        }
        res = crear_reserva(issue=3, pr=None, branch="feature/reused", claimed_at=T0)
        reservas = {(3, res.branch): res}

        fallos = gr.recuperar_prs_cerradas(reservas, ahora=T0, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertFalse(res.released)

    @patch("gestionar_reservas.obtener_pr")
    def test_recuperar_prs_cerradas_maneja_error_obtener_pr(self, mock_obtener_pr):
        mock_obtener_pr.side_effect = RuntimeError("Error API al consultar PR")
        res = crear_reserva(issue=4, pr=70, branch="feature/70")
        reservas = {(4, res.branch): res}

        fallos = gr.recuperar_prs_cerradas(reservas, ahora=T0, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertFalse(res.released)

    @patch("gestionar_reservas.obtener_pr_cerrada_de_rama")
    def test_recuperar_prs_cerradas_maneja_error_pr_cerrada_de_rama(self, mock_pr_cerrada_rama):
        mock_pr_cerrada_rama.side_effect = RuntimeError("Error API al consultar rama")
        res = crear_reserva(issue=5, pr=None, branch="feature/80")
        reservas = {(5, res.branch): res}

        fallos = gr.recuperar_prs_cerradas(reservas, ahora=T0, dry_run=True)

        self.assertEqual(fallos, 0)
        self.assertFalse(res.released)


if __name__ == "__main__":
    unittest.main()
