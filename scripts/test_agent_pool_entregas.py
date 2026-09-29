import io
import json
from contextlib import redirect_stdout
from datetime import datetime, timezone
from pathlib import Path
import tempfile
import unittest

import agent_pool_entregas as entregas


def pr(
    rama: str,
    estado: str = "OPEN",
    cuerpo: str = "",
    creada: str = "2026-09-29T12:00:00Z",
) -> dict:
    return {
        "number": 1,
        "headRefName": rama,
        "state": estado,
        "body": cuerpo,
        "createdAt": creada,
        "mergedAt": creada if estado == "MERGED" else None,
    }


class EntregasPoolTest(unittest.TestCase):
    def test_solo_ramas_canonicas_del_pool(self):
        self.assertTrue(entregas.es_pr_del_pool(pr("agent/qwen-1865-36620441784")))
        self.assertTrue(entregas.es_pr_del_pool(pr("agent/gemini-12-99")))
        self.assertFalse(entregas.es_pr_del_pool(pr("agent/protocol-v1-1866")))
        self.assertFalse(entregas.es_pr_del_pool(pr("feature/1-x")))
        self.assertFalse(entregas.es_pr_del_pool(pr("agent/qwen-1865")))

    def test_extrae_worker_del_cuerpo(self):
        cuerpo = "Implementacion autonoma mediante worker `qwen-fallback-3`"
        self.assertEqual("qwen-fallback-3", entregas.worker_de(pr("agent/qwen-1-2", cuerpo=cuerpo)))
        self.assertEqual("desconocido", entregas.worker_de(pr("agent/qwen-1-2")))

    def test_resumen_filtra_humanas_y_calcula_tasa(self):
        prs = [
            pr(
                "agent/qwen-10-100",
                "MERGED",
                "Implementacion autonoma mediante worker `qwen-primary`",
            ),
            pr(
                "agent/gemini-11-101",
                "OPEN",
                "Implementacion autonoma mediante worker `gemini-primary`",
            ),
            pr("agent/protocol-v1-1866", "MERGED"),
        ]
        resultado = entregas.resumen(prs)
        self.assertEqual(2, resultado["total"])
        self.assertEqual({"OPEN": 1, "MERGED": 1, "CLOSED": 0}, resultado["por_estado"])
        self.assertEqual(0.5, resultado["tasa_fusion"])
        self.assertEqual(1, resultado["por_worker"]["qwen-primary"]["MERGED"])
        self.assertEqual(1, resultado["por_worker"]["gemini-primary"]["total"])

    def test_filtro_desde_excluye_pr_antigua(self):
        prs = [
            pr("agent/qwen-1-1", creada="2026-09-27T23:59:59Z"),
            pr("agent/qwen-2-2", creada="2026-09-29T00:00:00Z"),
        ]
        resultado = entregas.resumen(
            prs,
            desde=datetime(2026, 9, 28, tzinfo=timezone.utc),
        )
        self.assertEqual(1, resultado["total"])

    def test_resumen_vacio_da_tasa_cero(self):
        resultado = entregas.resumen([])
        self.assertEqual(0, resultado["total"])
        self.assertEqual(0.0, resultado["tasa_fusion"])
        self.assertEqual({"OPEN": 0, "MERGED": 0, "CLOSED": 0}, resultado["por_estado"])

    def test_tabla_markdown(self):
        resultado = entregas.resumen(
            [
                pr(
                    "agent/qwen-10-100",
                    "MERGED",
                    "Implementacion autonoma mediante worker `qwen-primary`",
                )
            ]
        )
        salida = entregas.tabla(resultado)
        self.assertIn("| Worker | PRs | Fusionadas |", salida)
        self.assertIn("| qwen-primary | 1 | 1 |", salida)
        self.assertIn("Total: 1 PRs, 1 fusionadas (100%).", salida)

    def test_main_con_json_local_imprime_json_valido(self):
        with tempfile.TemporaryDirectory() as tmp:
            ruta = Path(tmp) / "prs.json"
            ruta.write_text(
                json.dumps(
                    [
                        pr(
                            "agent/qwen-10-100",
                            "MERGED",
                            "Implementacion autonoma mediante worker `qwen-primary`",
                        ),
                        pr("feature/humana", "OPEN"),
                    ]
                ),
                encoding="utf-8",
            )
            salida = io.StringIO()
            with redirect_stdout(salida):
                codigo = entregas.main(["--prs-json", str(ruta), "--json"])

        self.assertEqual(0, codigo)
        datos = json.loads(salida.getvalue())
        self.assertEqual(1, datos["total"])
        self.assertEqual(1, datos["por_estado"]["MERGED"])


if __name__ == "__main__":
    unittest.main()
