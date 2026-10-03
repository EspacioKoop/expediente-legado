import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MOVIMIENTO = ROOT / "godot" / "guion" / "juicio_combate_rival_movimiento_3d.gd"
HOST = ROOT / "godot" / "guion" / "juicio_combate_3d.gd"
VOLCAR = ROOT / "godot" / "guion" / "juicio_combate_ambiental_volcar_1772.gd"
PRUEBA = "res://pruebas/pruebas_combate_obstaculo_runtime_1772.gd"
RESUMEN = re.compile(r"combate_obstaculo_runtime_1772: (\d+) pasadas, 0 fallos")


class CombateObstaculoRuntime1772Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.movimiento = MOVIMIENTO.read_text(encoding="utf-8")
        cls.host = HOST.read_text(encoding="utf-8")
        cls.volcar = VOLCAR.read_text(encoding="utf-8")

    def test_movimiento_reutiliza_politica_y_runtime_volcar(self):
        self.assertIn('juicio_combate_obstaculo_1772.gd', self.movimiento)
        self.assertIn('anfitrion.get("_volcar_1772")', self.movimiento)
        self.assertIn('runtime.get("restante", 0.0)', self.movimiento)
        self.assertIn('get_node_or_null("VolumenTemporal")', self.movimiento)
        self.assertIn("OBSTACULO_1772", self.movimiento)
        self.assertIn(". planear(", self.movimiento)
        self.assertIn('int(anfitrion.get("_raiz"))', self.movimiento)

    def test_rodeo_solo_reorienta_el_desplazamiento_normal(self):
        self.assertIn('var desplazamiento: Vector3 = paso.get("desplazamiento"', self.movimiento)
        self.assertIn('match String(rodeo.get("intencion", "directo"))', self.movimiento)
        self.assertIn('"esperar":', self.movimiento)
        self.assertIn('"rodear":', self.movimiento)
        self.assertIn("direccion.normalized() * desplazamiento.length()", self.movimiento)
        self.assertIn("REGLAS", self.movimiento)
        self.assertIn(". limitar_a_arena(", self.movimiento)

    def test_no_crea_segunda_autoridad_de_combate(self):
        for prohibido in (
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "_aplicar_impacto_rival",
            "_determinacion_jugador",
            "_determinacion_rival",
            "terminado.emit",
            "loot",
            "xp",
        ):
            self.assertNotIn(prohibido, self.movimiento)

    def test_host_sigue_delegando_movimiento(self):
        self.assertIn("func _mover_rival(delta: float) -> void:", self.host)
        self.assertIn("RIVAL_MOVIMIENTO_3D.avanzar(self, delta)", self.host)
        self.assertNotIn("OBSTACULO_1772", self.host)

    def test_volcar_expone_unico_volumen_temporal(self):
        self.assertIn('colision.name = "VolumenTemporal"', self.volcar)
        self.assertIn('runtime["restante"]', self.volcar)
        self.assertIn("prop.collision_layer = 0", self.volcar)

    def test_regresion_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
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
        self.assertGreaterEqual(int(resumen.group(1)), 14, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
