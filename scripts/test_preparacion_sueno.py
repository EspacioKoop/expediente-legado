from pathlib import Path
import os
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "godot" / "guion" / "preparacion_sueno.gd"
DIA = ROOT / "godot" / "guion" / "dia_sueno_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class PreparacionSuenoTest(unittest.TestCase):
    def test_contrato_de_ui(self):
        panel = PANEL.read_text(encoding="utf-8")
        self.assertIn("class_name PreparacionSueno", panel)
        self.assertIn("for i in SeleccionNocturna.MAX_DOCUMENTOS", panel)
        self.assertIn('event.is_action_pressed("ui_cancel")', panel)
        self.assertIn("focus_neighbor_bottom", panel)
        self.assertIn("_seleccion.append(folio)", panel)
        self.assertIn("_seleccion.remove_at(indice)", panel)

    def test_dormir_pasa_antes_por_preparacion(self):
        dia = DIA.read_text(encoding="utf-8")
        self.assertIn("_abrir_preparacion_sueno()", dia)
        self.assertIn("panel.confirmada.connect(_confirmar_preparacion_sueno)", dia)
        self.assertIn("Jornada.preparar_sueno(jornada, seleccion)", dia)
        self.assertIn("_cerrar_preparacion_sueno(false)", dia)

    def test_textos_de_preparacion_existen(self):
        textos = TEXTOS.read_text(encoding="utf-8")
        for clave in (
            "SUENO_PREPARAR_TITULO",
            "SUENO_PREPARAR_AYUDA",
            "SUENO_PREPARAR_HUECO_VACIO",
            "SUENO_PREPARAR_CONFIRMAR",
            "SUENO_PREPARAR_CANCELAR",
        ):
            self.assertIn(clave + ",", textos)

    def test_smoke_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="preparacion-sueno-162-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "res://pruebas/preparacion_sueno_smoke.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
