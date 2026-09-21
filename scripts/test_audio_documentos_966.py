import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
SONIDO = ROOT / "godot" / "guion" / "sonido.gd"
CASOS = ROOT / "godot" / "datos" / "casos.json"
PRUEBA_GODOT = "pruebas/pruebas_audio_documentos_966.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class AudioDocumentos966Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.sonido = SONIDO.read_text(encoding="utf-8")
        cls.casos = json.loads(CASOS.read_text(encoding="utf-8"))

    def test_el_corte_antiguo_sale_de_fechas_reales_y_es_raro(self):
        fechados = []
        for caso in self.casos["casos"]:
            for registro in caso["registros"]:
                fecha = registro.get("fecha")
                if isinstance(fecha, str) and re.match(r"^\d{4}", fecha):
                    fechados.append(int(fecha[:4]))

        antiguos = [anio for anio in fechados if anio <= 1989]
        self.assertEqual(len(fechados), 43)
        self.assertEqual(len(antiguos), 5)
        self.assertLess(len(antiguos), len(fechados) // 4)

    def test_primera_lectura_usa_tono_y_relectura_sigue_en_clic(self):
        self.assertIn('Sonido.sonar(self, "documento", tono_documento(registro))', self.visor)
        self.assertIn('Sonido.sonar(self, "pulsar")', self.visor)
        self.assertIn("if not ya_visto:", self.visor)
        self.assertIn("ANIO_PAPEL_ANTIGUO_MAX := 1989", self.visor)
        self.assertIn("TONO_PAPEL_ANTIGUO := 0.82", self.visor)

    def test_sonido_reutiliza_el_mismo_asset_con_pitch_scale(self):
        self.assertIn("func sonar(nodo: Node, nombre: String, tono: float = 1.0)", self.sonido)
        self.assertIn("voz.pitch_scale = clampf(tono, 0.5, 2.0)", self.sonido)
        self.assertNotIn("documento_antiguo", self.sonido)

    def test_comportamiento_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
