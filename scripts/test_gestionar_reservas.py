from datetime import datetime, timedelta, timezone
import unittest

import gestionar_reservas as reservas


UTC = timezone.utc


def comentario(body: str, when: datetime) -> dict:
    return {"body": body, "created_at": when.isoformat().replace("+00:00", "Z")}


class GestionarReservasTest(unittest.TestCase):
    def test_claim_parsea_lease_y_release_es_idempotente_en_estado(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario(
                "CLAIM issue=#10 agent=Codex branch=feature/10-a files=a.gd goal=Probar algo lease=48h",
                t0,
            ),
            comentario("RELEASE issue=#10 motivo=entregado", t0 + timedelta(hours=1)),
        ]

        estado = reservas.reconstruir_reservas(comentarios)
        reserva = estado[(10, "feature/10-a")]

        self.assertEqual(48, reserva.lease_hours)
        self.assertEqual("Probar algo", reserva.goal)
        self.assertTrue(reserva.released)

    def test_heartbeat_renueva_lease(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario(
                "CLAIM issue=#11 agent=Codex branch=feature/11-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("HEARTBEAT issue=#11 branch=feature/11-a", t0 + timedelta(hours=40)),
        ]
        estado = reservas.reconstruir_reservas(comentarios)

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=60),
            lambda _: self.fail("no debe consultar PR"),
        )

        self.assertEqual([], acciones)

    def test_claim_sin_pr_caduca_tras_lease(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#12 agent=Codex branch=feature/12-a files=a.gd goal=Probar lease=48h",
                t0,
            )
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=49),
            lambda _: self.fail("no debe consultar PR"),
        )

        self.assertEqual("reserva-caducada", acciones[0][1])

    def test_pr_abierta_mantiene_reserva_aunque_venza_lease(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#13 agent=Codex branch=feature/13-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("PR_READY issue=#13 pr=#100 sha=abc pruebas=ok limites=ninguno", t0),
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(days=10),
            lambda _: {"number": 100, "state": "open", "merged_at": None},
        )

        self.assertEqual([], acciones)

    def test_pr_mergeada_libera_reserva(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#14 agent=Codex branch=feature/14-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("PR_READY issue=#14 pr=#101 sha=abc pruebas=ok limites=ninguno", t0),
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=1),
            lambda _: {
                "number": 101,
                "state": "closed",
                "merged_at": "2026-09-15T00:30:00Z",
                "merge_commit_sha": "deadbeef",
            },
        )

        self.assertEqual("merge-detectado-automaticamente", acciones[0][1])

    def test_pr_cerrada_sin_merge_libera_reserva(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#15 agent=Codex branch=feature/15-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("PR_READY issue=#15 pr=#102 sha=abc pruebas=ok limites=ninguno", t0),
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=1),
            lambda _: {"number": 102, "state": "closed", "merged_at": None},
        )

        self.assertEqual("PR-cerrado-sin-integrar", acciones[0][1])

    def test_migracion_libera_claim_legacy_anterior_al_corte(self):
        t0 = datetime(2026, 9, 14, 0, 0, tzinfo=UTC)
        cutoff = datetime(2026, 9, 15, 4, 6, 30, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario("CLAIM issue=#16 agent=Codex branch=feature/16-a files=a.gd goal=Legacy", t0)
        ])

        acciones = reservas.planificar_barrido(
            estado,
            cutoff + timedelta(hours=1),
            lambda _: self.fail("no debe consultar PR"),
            legacy_cutoff=cutoff,
        )

        self.assertEqual("migracion-legacy-sin-trabajo-activo", acciones[0][1])

    def test_migracion_no_libera_claim_legacy_posterior_al_corte(self):
        cutoff = datetime(2026, 9, 15, 4, 6, 30, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#17 agent=Codex branch=feature/17-a files=a.gd goal=Legacy nuevo",
                cutoff + timedelta(minutes=1),
            )
        ])

        acciones = reservas.planificar_barrido(
            estado,
            cutoff + timedelta(hours=3),
            lambda _: self.fail("no debe consultar PR"),
            legacy_cutoff=cutoff,
        )

        self.assertEqual([], acciones)


if __name__ == "__main__":
    unittest.main()
