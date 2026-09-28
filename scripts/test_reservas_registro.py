from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import reservas_registro as rr

ROOT = Path(__file__).resolve().parents[1]
T0 = datetime(2026, 9, 28, 10, 0, tzinfo=timezone.utc)


def comentario(ident, body, minutos=0):
    return {
        "id": ident,
        "created_at": (T0 + timedelta(minutes=minutos)).isoformat().replace("+00:00", "Z"),
        "body": body,
    }


def claim(issue, rama, files, lease="48h"):
    return f"CLAIM issue=#{issue} agent=A branch={rama} files={files} goal=objetivo lease={lease}"


class SolapesTest(unittest.TestCase):
    def test_misma_ruta_o_directorio_contenedor(self):
        self.assertTrue(rr.solapan("godot/guion/a.gd", "godot/guion/a.gd"))
        self.assertTrue(rr.solapan("godot/guion/", "godot/guion/a.gd"))
        self.assertTrue(rr.solapan("godot/guion/a.gd", "godot/guion"))

    def test_prefijo_de_nombre_no_es_solape(self):
        self.assertFalse(rr.solapan("godot/guion/a.gd", "godot/guion/a.gd.uid"))
        self.assertFalse(rr.solapan("scripts/test_a.py", "scripts/test_ab.py"))
        self.assertFalse(rr.solapan("", "godot"))


class VigenciaTest(unittest.TestCase):
    def test_lease_caduca_sin_esperar_al_barrido(self):
        com = [comentario(1, claim(10, "feature/10-a", "a.gd", lease="1h"))]
        self.assertEqual(1, len(rr.vigentes(com, T0 + timedelta(minutes=59))))
        self.assertEqual([], rr.vigentes(com, T0 + timedelta(hours=2)))

    def test_heartbeat_renueva_y_pr_ready_mantiene_sin_reloj(self):
        com = [
            comentario(1, claim(10, "feature/10-a", "a.gd", lease="1h")),
            comentario(2, "HEARTBEAT issue=#10 branch=feature/10-a", minutos=50),
            comentario(3, claim(11, "feature/11-b", "b.gd", lease="1h")),
            comentario(4, "PR_READY issue=#11 pr=#99 sha=x pruebas=ok limites=n", minutos=5),
        ]
        ramas = {r.reserva.branch for r in rr.vigentes(com, T0 + timedelta(hours=10))}
        self.assertEqual({"feature/11-b"}, ramas)
        ramas = {r.reserva.branch for r in rr.vigentes(com, T0 + timedelta(minutes=100))}
        self.assertEqual({"feature/10-a", "feature/11-b"}, ramas)

    def test_release_por_rama_no_libera_otra_rama_del_issue(self):
        com = [
            comentario(1, claim(10, "feature/10-a", "a.gd")),
            comentario(2, claim(10, "feature/10-b", "b.gd")),
            comentario(3, "RELEASE issue=#10 branch=feature/10-a motivo=x"),
        ]
        self.assertEqual(["feature/10-b"], [r.reserva.branch for r in rr.vigentes(com, T0)])

    def test_claim_no_canonico_no_crea_bloqueo_fantasma(self):
        # Casos reales de #182 que el Python inline de los workflows daba por
        # activos para siempre: nunca caducan porque el barrido no los reconoce.
        com = [
            comentario(1, "CLAIM issue=#672,#674,#677 agent=O branch=test/x files=a.gd goal=g"),
            comentario(2, "CLAIM issue=#275 agent=C branch=feature/y pr=#1383 files=a.gd goal=g"),
        ]
        self.assertEqual([], rr.vigentes(com, T0))


class ConflictosTest(unittest.TestCase):
    def test_choca_solo_con_reservas_anteriores_que_solapan(self):
        com = [
            comentario(1, claim(10, "feature/10-a", "godot/guion/a.gd,docs/x.md")),
            comentario(2, claim(11, "feature/11-b", "godot/pruebas/b.gd")),
            comentario(3, claim(12, "agent/qwen-12-1", "godot/guion/a.gd,godot/pruebas/c.gd")),
            comentario(4, claim(13, "feature/13-d", "godot/pruebas/c.gd")),
        ]
        resultado = rr.conflictos(com, claim_id=3, issue=12, branch="agent/qwen-12-1", ahora=T0)
        self.assertTrue(resultado["mine_found"])
        self.assertEqual(
            [{"issue": 10, "branch": "feature/10-a", "agent": "A", "claim_id": 1, "paths": ["godot/guion/a.gd"]}],
            resultado["conflicts"],
        )

    def test_reserva_caducada_no_bloquea(self):
        com = [
            comentario(1, claim(10, "feature/10-a", "a.gd", lease="1h")),
            comentario(2, claim(12, "agent/qwen-12-1", "a.gd"), minutos=120),
        ]
        resultado = rr.conflictos(
            com, claim_id=2, issue=12, branch="agent/qwen-12-1", ahora=T0 + timedelta(hours=3)
        )
        self.assertEqual([], resultado["conflicts"])

    def test_claim_propio_perdido_se_informa(self):
        com = [comentario(1, claim(10, "feature/10-a", "a.gd"))]
        resultado = rr.conflictos(com, claim_id=99, issue=12, branch="agent/qwen-12-1", ahora=T0)
        self.assertEqual({"mine_found": False, "conflicts": []}, resultado)

    def test_reclaim_de_la_misma_rama_usa_el_id_mas_reciente(self):
        com = [
            comentario(1, claim(12, "agent/qwen-12-1", "a.gd")),
            comentario(2, claim(10, "feature/10-a", "a.gd")),
            comentario(3, claim(12, "agent/qwen-12-1", "a.gd")),
        ]
        resultado = rr.conflictos(com, claim_id=3, issue=12, branch="agent/qwen-12-1", ahora=T0)
        self.assertEqual(["feature/10-a"], [c["branch"] for c in resultado["conflicts"]])

    def test_cli(self):
        com = [
            comentario(1, claim(10, "feature/10-a", "a.gd")),
            comentario(2, claim(12, "agent/qwen-12-1", "a.gd")),
        ]
        with tempfile.TemporaryDirectory() as tmp:
            datos = Path(tmp) / "c.json"
            datos.write_text(json.dumps(com), encoding="utf-8")
            salida = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "scripts" / "reservas_registro.py"),
                    "conflictos",
                    "--comments",
                    str(datos),
                    "--claim-id",
                    "2",
                    "--issue",
                    "12",
                    "--branch",
                    "agent/qwen-12-1",
                    "--now",
                    "2026-09-28T11:00:00Z",
                ],
                check=True,
                capture_output=True,
                text=True,
                cwd=ROOT / "scripts",
            ).stdout
        self.assertEqual(["feature/10-a"], [c["branch"] for c in json.loads(salida)["conflicts"]])


class WorkflowsUsanLaCapaTest(unittest.TestCase):
    def test_worker_reserva_con_la_capa_y_sin_parser_propio(self):
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")
        paso = worker.split("name: Validar plan y reservar rutas", 1)[1].split("\n      - ", 1)[0]
        self.assertIn("python3 scripts/reservas_registro.py conflictos", paso)
        self.assertIn("--jq '.[]|{id,created_at,body}'", paso)
        # El parser inline daba por vivos CLAIM no canónicos para siempre.
        self.assertNotIn("claim_re", paso)
        self.assertNotIn("release_re", paso)
        self.assertIn("CLAIM perdido", paso)
        self.assertIn('echo "reserved=true" >> "$GITHUB_OUTPUT"', paso)


if __name__ == "__main__":
    unittest.main()
