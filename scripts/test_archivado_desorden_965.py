import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
BANDEJA = ROOT / "godot" / "guion" / "archivado_bandeja.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_archivado_app.gd"
DESORDEN = ROOT / "godot" / "guion" / "archivado_desorden_3d.gd"
SMOKE = "pruebas/pruebas_archivado_desorden_965.gd"


class ArchivadoDesorden965Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.bandeja = BANDEJA.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.desorden = DESORDEN.read_text(encoding="utf-8")

    def test_desorden_se_deriva_del_estado_existente(self):
        self.assertIn("static func desorden_por_destino", self.bandeja)
        self.assertIn('estado.get("colocaciones", [])', self.bandeja)
        self.assertIn('estado.get("pendientes", [])', self.bandeja)
        self.assertNotIn('"desorden":', self.bandeja)

    def test_busqueda_se_demora_sin_bloquear_la_interaccion(self):
        self.assertIn("DEMORA_BUSQUEDA_POR_ERROR := 0.35", self.bandeja)
        self.assertIn("DEMORA_BUSQUEDA_MAX := 1.4", self.bandeja)
        self.assertIn("static func demora_busqueda", self.bandeja)
        self.assertIn("create_timer(demora)", self.controlador)
        self.assertIn('_texto("buscando_carpeta")', self.controlador)
        self.assertIn("_cancelar_busqueda()", self.controlador)
        self.assertNotIn("await get_tree().create_timer", self.controlador)

    def test_controlador_reconstruye_y_actualiza_el_espacio(self):
        self.assertIn("_sincronizar_desorden_espacial(host)", self.controlador)
        self.assertIn("ArchivadoBandeja.desorden_por_destino", self.controlador)
        self.assertIn("ArchivadoDesorden3D.aplicar", self.controlador)
        bloque = self.controlador.split("func _archivar_en", 1)[1].split(
            "func _sincronizar_desorden_espacial", 1
        )[0]
        self.assertIn("_persistir(host)", bloque)
        self.assertIn("_sincronizar_desorden_espacial(host)", bloque)

    def test_pilas_son_visuales_y_acotadas(self):
        self.assertIn("class_name ArchivadoDesorden3D", self.desorden)
        self.assertIn("MAX_VISIBLES := 3", self.desorden)
        self.assertIn("MeshInstance3D.new()", self.desorden)
        self.assertIn("BoxMesh.new()", self.desorden)
        codigo = "\n".join(
            linea for linea in self.desorden.splitlines()
            if not linea.lstrip().startswith("#")
        )
        self.assertNotIn("CollisionShape3D", codigo)
        self.assertNotIn("StaticBody3D", codigo)
        self.assertNotIn("NavigationObstacle3D", codigo)

    def test_no_inventa_otra_persistencia(self):
        combinado = self.controlador + self.desorden
        self.assertNotIn('jornada["archivado_desorden"', combinado)
        self.assertNotIn("FileAccess", self.desorden)
        self.assertNotIn("Partida", self.desorden)

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
        self.assertIn("issue_965_desorden:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
