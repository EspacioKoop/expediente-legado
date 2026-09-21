import json
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
DETALLES = ROOT / "godot" / "guion" / "detalles_meticulosidad.gd"
CATALOGO_DETALLES = ROOT / "godot" / "datos" / "detalles_meticulosidad.json"
CASOS = ROOT / "godot" / "datos" / "casos.json"
SMOKE = "pruebas/issue_961_smoke.gd"


class Meticulosidad961Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.estado = ESTADO.read_text(encoding="utf-8")
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.anexos = ANEXOS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.detalles = DETALLES.read_text(encoding="utf-8")
        cls.catalogo_detalles = json.loads(CATALOGO_DETALLES.read_text(encoding="utf-8"))
        cls.casos = json.loads(CASOS.read_text(encoding="utf-8"))["casos"]

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

    def test_detalles_autorados_son_opcionales_y_referencian_folios_reales(self):
        registros = {
            registro["id"]
            for caso in self.casos
            for registro in caso["registros"]
        }
        self.assertGreaterEqual(len(self.catalogo_detalles), 8)
        self.assertTrue(set(self.catalogo_detalles).issubset(registros))
        eventos = {"lectura_completa", "relectura", "marcador", "relacion"}
        motivos = {"fecha", "margen", "folio", "relacion", "relectura"}
        for documento_id, detalles in self.catalogo_detalles.items():
            self.assertIsInstance(detalles, list, documento_id)
            self.assertGreater(len(detalles), 0, documento_id)
            for detalle in detalles:
                self.assertIn(detalle["evento"], eventos, detalle["id"])
                self.assertIn(detalle["motivo"], motivos, detalle["id"])
                self.assertFalse(detalle["critico"], detalle["id"])
                self.assertTrue(detalle["texto"].strip(), detalle["id"])

    def test_el_visor_revela_detalles_sin_convertirlos_en_pistas(self):
        self.assertIn("RUTA_DETALLES_METICULOSIDAD", self.capa)
        self.assertIn("_actualizar_detalles_meticulosidad()", self.capa)
        self.assertRegex(self.capa, r"DetallesMeticulosidadCatalogo\s*\.\s*visibles\(")
        combinado = self.capa + self.detalles
        self.assertNotIn("pistas_descubiertas", combinado)
        self.assertNotIn("Acusacion", combinado)
        self.assertNotIn("descubiertas.append", combinado)
        self.assertNotIn("gastar_accion", combinado)
        self.assertIn('detalle.get("critico", true)', self.detalles)

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
