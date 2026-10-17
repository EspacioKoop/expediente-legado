#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de gestionar_reservas.py."""

from __future__ import annotations

import unittest
from datetime import datetime, timezone

from scripts.gestionar_reservas import (
    comentario_confiable,
    eventos_de_comentario,
    motivo_de_cierre,
    parse_fecha,
)


class TestGestionarReservasEventos(unittest.TestCase):

    def test_comentario_confiable_autor_repo(self) -> None:
        """Autor del repositorio con distintas asociaciones de confianza."""
        for asociacion in ("OWNER", "MEMBER", "COLLABORATOR", "owner", " member "):
            with self.subTest(asociacion=asociacion):
                comentario = {
                    "author_association": asociacion,
                    "user": {"login": "dev-interno"},
                }
                self.assertTrue(comentario_confiable(comentario))

    def test_comentario_confiable_github_actions_bot(self) -> None:
        """github-actions[bot] debe ser confiable incluso con author_association NONE o vacia."""
        comentario_1 = {
            "author_association": "NONE",
            "user": {"login": "github-actions[bot]"},
        }
        comentario_2 = {
            "authorAssociation": "",
            "author": "github-actions[bot]",
        }
        self.assertTrue(comentario_confiable(comentario_1))
        self.assertTrue(comentario_confiable(comentario_2))

    def test_comentario_confiable_externo(self) -> None:
        """Un usuario externo con author_association NONE no es confiable."""
        comentario = {
            "author_association": "NONE",
            "user": {"login": "usuario-externo"},
        }
        self.assertFalse(comentario_confiable(comentario))

    def test_parse_fecha_utc_y_offsets(self) -> None:
        """parse_fecha maneja la sufijo Z y desplazamientos horarios convirtiendo a UTC."""
        dt_z = parse_fecha("2026-10-17T15:30:00Z")
        self.assertEqual(dt_z, datetime(2026, 10, 17, 15, 30, 0, tzinfo=timezone.utc))

        dt_offset = parse_fecha("2026-10-17T17:30:00+02:00")
        self.assertEqual(dt_offset, datetime(2026, 10, 17, 15, 30, 0, tzinfo=timezone.utc))

    def test_eventos_de_comentario_claim_pr_ready_release_y_citas(self) -> None:
        """Extrae CLAIM, PR_READY y RELEASE en un mismo cuerpo, ignorando lineas citadas con >."""
        cuerpo = (
            "> CLAIM issue=#100 agent=qwen branch=fe/old files=a.py goal=old\n"
            "> PR_READY issue=#100 pr=#10\n"
            "> RELEASE issue=#100\n"
            "CLAIM issue=#182 agent=jules branch=feature/test files=scripts/test_x.py goal=Probar eventos\n"
            "PR_READY issue=#182 pr=#42 branch=feature/test\n"
            "RELEASE issue=#182 branch=feature/test\n"
        )
        eventos = eventos_de_comentario(cuerpo)
        self.assertEqual(len(eventos), 3)

        tipos = [e[0] for e in eventos]
        self.assertEqual(tipos, ["claim", "pr_ready", "release"])

        claim_match = eventos[0][1]
        self.assertEqual(claim_match.group("issue"), "182")
        self.assertEqual(claim_match.group("agent"), "jules")
        self.assertEqual(claim_match.group("branch"), "feature/test")

        pr_ready_match = eventos[1][1]
        self.assertEqual(pr_ready_match.group("issue"), "182")
        self.assertEqual(pr_ready_match.group("pr"), "42")

        release_match = eventos[2][1]
        self.assertEqual(release_match.group("issue"), "182")

    def test_motivo_de_cierre(self) -> None:
        """Determina el motivo de cierre segun si la PR fue integrada (merged_at)."""
        pr_integrada = {"number": 1, "merged_at": "2026-10-17T12:00:00Z"}
        pr_cerrada_sin_merge = {"number": 2, "merged_at": None}

        self.assertEqual(motivo_de_cierre(pr_integrada), "merge-detectado-automaticamente")
        self.assertEqual(motivo_de_cierre(pr_cerrada_sin_merge), "PR-cerrado-sin-integrar")


if __name__ == "__main__":
    unittest.main()
