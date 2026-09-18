import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")
CONTROLLER = ROOT / "godot" / "guion" / "dia_relacion_onirica_app.gd"
ECOS = ROOT / "godot" / "guion" / "dia_ecos_archivo_app.gd"
VERTICAL = ROOT / "godot" / "guion" / "sueno_relacion_onirica_3d.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class RelacionOniricaTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_relacion_onirica.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 24, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_wiring_prioriza_relaciones_no_triviales(self):
        codigo = CONTROLLER.read_text(encoding="utf-8")
        compacto = "".join(codigo.split())
        self.assertIn("process_priority=-10", compacto)
        self.assertIn('pista.has("registroOrigen2")', compacto)
        self.assertIn("registros_leidos.size()<RelacionOnirica.MIN_DOCUMENTOS", compacto)
        self.assertIn("RelacionOnirica.crear(", compacto)
        self.assertIn("dia.conectar_recompensa_onirica(relacion.nucleo,caso)", compacto)
        self.assertIn('mundo.set_meta("puzzle_onirico_montado","relacion")', compacto)

    def test_ecos_respeta_la_reserva_de_un_puzzle_por_sala(self):
        codigo = "".join(ECOS.read_text(encoding="utf-8").split())
        self.assertIn('mundo.has_meta("puzzle_onirico_montado")', codigo)
        self.assertIn('mundo.set_meta("puzzle_onirico_montado","ecos")', codigo)

    def test_vertical_usa_interaccion_comun_y_no_crea_barrera(self):
        codigo = VERTICAL.read_text(encoding="utf-8")
        self.assertIn("Interactuable3D.new()", codigo)
        self.assertIn("activado.connect(_al_activar_documento.bind(indice))", codigo)
        self.assertIn("CollisionShape3D.new()", codigo)
        for cuerpo in ("StaticBody3D", "CharacterBody3D", "NavigationObstacle3D"):
            self.assertNotIn(cuerpo, codigo)
        self.assertNotIn("Input.", codigo)
        self.assertIn("No hay segundo intento.", codigo)

    def test_controller_esta_montado_antes_de_ecos(self):
        escena = DIA.read_text(encoding="utf-8")
        relacion = escena.index('[node name="RelacionOniricaController"')
        ecos = escena.index('[node name="EcosArchivoController"')
        self.assertLess(relacion, ecos)
        self.assertIn('path="res://guion/dia_relacion_onirica_app.gd"', escena)


if __name__ == "__main__":
    unittest.main()
