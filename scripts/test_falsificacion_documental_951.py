import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "falsificacion_documental.gd"
VISOR = ROOT / "godot" / "guion" / "visor_metadatos_app.gd"
SMOKE = "pruebas/pruebas_falsificacion_951.gd"


class FalsificacionDocumental951Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modelo = MODELO.read_text(encoding="utf-8")
        cls.visor = VISOR.read_text(encoding="utf-8")

    def test_modelo_es_temporal_determinista_y_sin_io(self):
        self.assertIn('"temporal": true', self.modelo)
        codigo = "\n".join(
            linea for linea in self.modelo.splitlines()
            if not linea.lstrip().startswith("#")
        )
        self.assertNotIn("rand", codigo.lower())
        for token in ("FileAccess", "DirAccess", "Partida", "guardar("):
            self.assertNotIn(token, codigo)

    def test_visor_ofrece_tres_intervenciones_diegéticas(self):
        for clave, valor in (
            ("VISOR_FALSIFICACION_951_FECHA", '"fecha"'),
            ("VISOR_FALSIFICACION_951_SELLO", '"sello"'),
            ("VISOR_FALSIFICACION_951_FIRMA", '"firma"'),
        ):
            self.assertIn(f'tr("{clave}")', self.visor)
            self.assertIn(valor, self.visor)
        self.assertIn("OptionButton.new()", self.visor)
        self.assertIn("get_selected_metadata()", self.visor)

    def test_crear_copia_no_persiste_ni_descubre_pistas(self):
        inicio = self.visor.index("func _crear_copia_falsificada()")
        fin = self.visor.index("\n\nfunc _reiniciar_analisis_documental()", inicio)
        metodo = self.visor[inicio:fin]
        for token in (
            "_guardar_o_avisar",
            "partida.estado",
            "pistas_descubiertas",
            "descubiertas.append",
            "Jornada.gastar",
        ):
            self.assertNotIn(token, metodo)
        self.assertIn("_borrador_falsificacion =", metodo)

    def test_revision_interna_es_narrativa_y_no_persistente(self):
        self.assertIn("static func resolver_revision", self.modelo)
        inicio = self.visor.index("func _resolver_revision_falsificacion()")
        fin = self.visor.index("\n\nfunc _reiniciar_analisis_documental()", inicio)
        metodo = self.visor[inicio:fin]
        for token in (
            "_guardar_o_avisar",
            "partida.estado",
            "pistas_descubiertas",
            "descubiertas.append",
            "Jornada.gastar",
        ):
            self.assertNotIn(token, metodo)
        for clave in (
            "VISOR_FALSIFICACION_951_REVISION_ACEPTADA",
            "VISOR_FALSIFICACION_951_REVISION_COTEJO",
            "VISOR_FALSIFICACION_951_REVISION_RETENIDA",
        ):
            self.assertIn(f'"{clave}"', self.visor)

    def test_calidad_y_riesgo_se_traducen_desde_claves_explicitas(self):
        for clave in (
            "VISOR_FALSIFICACION_951_CALIDAD_BAJA",
            "VISOR_FALSIFICACION_951_CALIDAD_MEDIA",
            "VISOR_FALSIFICACION_951_CALIDAD_ALTA",
            "VISOR_FALSIFICACION_951_RIESGO_ALTO",
            "VISOR_FALSIFICACION_951_RIESGO_MEDIO",
            "VISOR_FALSIFICACION_951_RIESGO_BAJO",
        ):
            self.assertIn(f'"{clave}"', self.visor)

    def test_smoke_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                SMOKE,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("issue_951_falsificacion:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
