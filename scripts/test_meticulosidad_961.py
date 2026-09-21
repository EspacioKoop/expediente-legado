import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESTADO = ROOT / "godot" / "guion" / "meticulosidad.gd"
CAPA = ROOT / "godot" / "guion" / "visor_metadatos_app.gd"
ANEXOS = ROOT / "godot" / "guion" / "visor_anexos_app.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_atencion_documental.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
SMOKE = "pruebas/issue_961_smoke.gd"


class Meticulosidad961Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.estado = ESTADO.read_text(encoding="utf-8")
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.anexos = ANEXOS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")

    def test_el_visor_registra_gestos_existentes_sin_barra(self):
        self.assertIn('extends "res://guion/visor_anotaciones_app.gd"', self.capa)
        for evento in ("relectura", "lectura_completa", "marcador", "relacion"):
            self.assertIn(f'"{evento}"', self.capa + self.estado)
        self.assertIn("get_v_scroll_bar()", self.capa)
        self.assertNotIn("ProgressBar", self.capa + self.estado)
        self.assertNotIn("TextureProgressBar", self.capa + self.estado)

    def test_la_capa_queda_en_la_cadena_real_del_visor(self):
        self.assertIn(
            'extends "res://guion/visor_metadatos_app.gd"',
            self.anexos,
        )

    def test_el_sueno_consume_motivos_sin_tocar_objetivos(self):
        self.assertIn("Meticulosidad.motivos_oniricos(dia.jornada)", self.controlador)
        self.assertRegex(self.controlador, r"SuenoAtencionDocumental\s*\.\s*montar\(")
        self.assertIn('eco.set_meta("decorativo", true)', self.sueno)
        self.assertNotIn("CollisionShape3D", self.sueno)
        self.assertNotIn("SuenoObjetivos", self.sueno)
        self.assertNotIn("objetivos_requeridos", self.sueno)
        self.assertNotIn("pistas_descubiertas", self.estado + self.capa + self.sueno)

    def test_el_estado_es_diario_e_idempotente(self):
        self.assertIn('const CAMPO_JORNADA := "meticulosidad_hoy"', self.estado)
        self.assertIn("eventos.has(evento)", self.estado)
        self.assertIn('int(jornada.get("dia", 0))', self.estado)
        self.assertIn("PUNTOS_MAX", self.estado)

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
        self.assertIn("issue_961:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
