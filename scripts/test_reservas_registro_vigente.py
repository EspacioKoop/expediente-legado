from datetime import datetime, timedelta, timezone
from dataclasses import FrozenInstanceError
import unittest

import gestionar_reservas as registro
import reservas_registro as rr

T0 = datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc)


def crear_reserva_sintetica(
    issue: int = 10,
    agent: str = "A",
    branch: str = "feature/10-a",
    files: str = "a.gd,b.gd",
    goal: str = "objetivo",
    claimed_at: datetime = T0,
    last_activity: datetime = T0,
    lease_hours: int | None = 48,
    pr: int | None = None,
    released: bool = False,
) -> registro.Reserva:
    return registro.Reserva(
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


def crear_comentario_sintetico(
    ident: int,
    body: str,
    minutos_desde_t0: int = 0,
    asociacion: str = "MEMBER",
    login: str = "maintainer",
) -> dict:
    created_at = (T0 + timedelta(minutes=minutos_desde_t0)).isoformat().replace("+00:00", "Z")
    return {
        "id": ident,
        "created_at": created_at,
        "body": body,
        "author_association": asociacion,
        "user": {"login": login},
    }


class TestReservaVigente(unittest.TestCase):
    def test_construccion_y_atributos(self):
        reserva = crear_reserva_sintetica(issue=42, branch="agent/test-42")
        rv = rr.ReservaVigente(reserva=reserva, claim_id=101)

        self.assertEqual(rv.reserva, reserva)
        self.assertEqual(rv.reserva.issue, 42)
        self.assertEqual(rv.reserva.branch, "agent/test-42")
        self.assertEqual(rv.claim_id, 101)

    def test_inmutabilidad_frozen(self):
        reserva = crear_reserva_sintetica()
        rv = rr.ReservaVigente(reserva=reserva, claim_id=100)

        with self.assertRaises((FrozenInstanceError, AttributeError)):
            rv.claim_id = 200  # type: ignore[misc]

        with self.assertRaises((FrozenInstanceError, AttributeError)):
            rv.reserva = crear_reserva_sintetica(issue=99)  # type: ignore[misc]

    def test_igualdad_dataclass(self):
        reserva_a = crear_reserva_sintetica(issue=1)
        reserva_b = crear_reserva_sintetica(issue=1)
        reserva_c = crear_reserva_sintetica(issue=2)

        rv1 = rr.ReservaVigente(reserva=reserva_a, claim_id=10)
        rv2 = rr.ReservaVigente(reserva=reserva_b, claim_id=10)
        rv3 = rr.ReservaVigente(reserva=reserva_a, claim_id=20)
        rv4 = rr.ReservaVigente(reserva=reserva_c, claim_id=10)

        self.assertEqual(rv1, rv2)
        self.assertNotEqual(rv1, rv3)
        self.assertNotEqual(rv1, rv4)

    def test_propiedad_rutas_varias_configuraciones(self):
        casos = [
            ("scripts/a.py,scripts/b.py", ["scripts/a.py", "scripts/b.py"]),
            ("godot/escena.tscn", ["godot/escena.tscn"]),
            ("", []),
            (",scripts/a.py,,scripts/b.py,", ["scripts/a.py", "scripts/b.py"]),
            (",,,", []),
        ]

        for files, esperado in casos:
            with self.subTest(files=files):
                reserva = crear_reserva_sintetica(files=files)
                rv = rr.ReservaVigente(reserva=reserva, claim_id=50)
                self.assertEqual(rv.rutas, esperado)

    def test_integracion_vigentes_ordena_por_claim_id(self):
        claim_body_1 = "CLAIM issue=#20 agent=A branch=feature/20 files=x.py goal=test lease=24h"
        claim_body_2 = "CLAIM issue=#10 agent=B branch=feature/10 files=y.py goal=test lease=24h"

        comentarios = [
            crear_comentario_sintetico(200, claim_body_1, minutos_desde_t0=0),
            crear_comentario_sintetico(100, claim_body_2, minutos_desde_t0=5),
        ]

        lista_vigentes = rr.vigentes(comentarios, T0)

        self.assertEqual(len(lista_vigentes), 2)
        self.assertIsInstance(lista_vigentes[0], rr.ReservaVigente)
        self.assertIsInstance(lista_vigentes[1], rr.ReservaVigente)

        # Confirmar que está ordenado por claim_id (100 < 200)
        self.assertEqual(lista_vigentes[0].claim_id, 100)
        self.assertEqual(lista_vigentes[0].reserva.issue, 10)
        self.assertEqual(lista_vigentes[1].claim_id, 200)
        self.assertEqual(lista_vigentes[1].reserva.issue, 20)


if __name__ == "__main__":
    unittest.main()
