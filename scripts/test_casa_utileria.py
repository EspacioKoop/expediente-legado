import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"
LAMPARA = ROOT / "godot" / "guion" / "lampara_interactiva_3d.gd"
TELEVISOR = ROOT / "godot" / "guion" / "television_interactiva_3d.gd"
PORTATIL = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
ALMACENAMIENTO = ROOT / "godot" / "guion" / "almacenamiento_casa_interactivo_3d.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
PRUEBA_GODOT = "pruebas/pruebas_almacenamiento_casa.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CasaUtileriaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.lampara = LAMPARA.read_text(encoding="utf-8")
        cls.televisor = TELEVISOR.read_text(encoding="utf-8")
        cls.portatil = PORTATIL.read_text(encoding="utf-8")
        cls.almacenamiento = ALMACENAMIENTO.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_se_monta_solo_en_casa(self):
        self.assertIn('elif fase == "casa":', self.dia)
        self.assertIn("CasaUtileria.montar(_mundo)", self.dia)

    def test_anade_anclas_domesticas_e_interacciones(self):
        self.assertIn('mesa.name = "MesitaCasa"', self.utileria)
        self.assertIn('lampara.name = "LamparaPieCasa"', self.utileria)
        self.assertIn('portatil.name = "ConsolaPortatil98"', self.utileria)
        self.assertIn('televisor.name = "TelevisorCasaInteractuable"', self.utileria)
        self.assertIn('almacenamiento.name = "AlmacenamientoCasa"', self.utileria)
        self.assertIn("LamparaInteractiva3D.new()", self.utileria)
        self.assertIn("ConsolaPortatil98.new()", self.utileria)
        self.assertIn("TelevisionInteractiva3D.new()", self.utileria)
        self.assertIn("AlmacenamientoCasaInteractivo3D.new()", self.utileria)
        self.assertIn("BoxMesh.new()", self.utileria)
        self.assertIn("CylinderMesh.new()", self.utileria)

    def test_compone_zonas_domesticas_reconocibles(self):
        self.assertIn("montar_zonas_domesticas(raiz)", self.utileria)
        for nombre in ("CamaCasa", "CuencoGato3D", "SofaCasa", "CocinaCasa", "FregaderoCasa", "NeveraCasa", "VentanaCasa", "EstanteriaComprasCasa"):
            self.assertIn(nombre, self.utileria)
        self.assertIn('_ancla_salida("sueño"', self.utileria)
        self.assertIn("_ancla_cuenco(", self.utileria)
        self.assertIn("Vector3(-0.95, 0.0, 1.4)", self.utileria)
        self.assertIn("Vector3(4.80, 0.0, -0.15)", self.utileria)
        self.assertIn("Vector3(-2.10, 1.65, -3.42)", self.utileria)

    def test_cama_y_cuenco_reutilizan_anclas_de_gameplay(self):
        self.assertIn('for salida in EspaciosCatalogo.CASA.get("salidas", [])', self.utileria)
        self.assertIn('String(salida.get("destino", "")) != destino', self.utileria)
        self.assertIn('EspaciosCatalogo.CASA.get("sitios_gato", [])', self.utileria)
        self.assertNotIn('"destino": "sueño"', self.utileria)
        self.assertNotIn('"destino": "cuenco"', self.utileria)

    def test_distribucion_no_introduce_pantallas_ni_texto_legible(self):
        self.assertNotIn("Label.new()", self.utileria)
        self.assertNotIn("TextMesh.new()", self.utileria)
        self.assertNotIn("RichTextLabel.new()", self.utileria)

    def test_lampara_reutiliza_interaccion_y_luz_real(self):
        self.assertIn("extends Interactuable3D", self.lampara)
        self.assertIn("verbo = Verbo.ENCENDER", self.lampara)
        self.assertIn("OmniLight3D.new()", self.lampara)
        self.assertIn("CollisionShape3D.new()", self.lampara)
        self.assertIn('return "Apagar lámpara"', self.lampara)
        self.assertIn("_luz.visible = _encendida", self.lampara)

    def test_televisor_reutiliza_modelo_real_y_alterna_feedback(self):
        self.assertIn("EspaciosCatalogo.CASA", self.utileria)
        self.assertIn('String(bulto.get("modelo", "")) != "televisionVintage"', self.utileria)
        self.assertIn('televisor.position = bulto["pos"]', self.utileria)
        self.assertIn('televisor.configurar(bulto["tam"])', self.utileria)
        self.assertIn("extends Interactuable3D", self.televisor)
        self.assertIn("verbo = Verbo.ENCENDER", self.televisor)
        self.assertIn("CollisionShape3D.new()", self.televisor)
        self.assertIn("OmniLight3D.new()", self.televisor)
        self.assertIn('return "Apagar televisor"', self.televisor)
        self.assertIn("_brillo.visible = _encendida", self.televisor)
        self.assertIn('cristal_pantalla.name = "CristalPantallaTV"', self.televisor)
        self.assertIn("Pantalla.montar(", re.sub(r"\s+", "", self.televisor))
        self.assertIn('emision_pantalla.name = "EmisionPantallaTV"', self.televisor)

    def test_portatil_es_interactiva_y_tiene_controles_visibles(self):
        self.assertIn("extends Interactuable3D", self.portatil)
        self.assertIn("verbo = Verbo.USAR", self.portatil)
        self.assertIn("CollisionShape3D.new()", self.portatil)
        self.assertIn("BoxMesh.new()", self.portatil)
        self.assertIn("CylinderMesh.new()", self.portatil)
        self.assertIn("_actualizar_pantalla()", self.portatil)
        self.assertIn("CatalogoRomsUsuario.listar()", self.portatil)

    def test_almacenamiento_reutiliza_abrir_cerrar_y_feedback_fisico(self):
        self.assertIn('extends "res://guion/interactuable_3d.gd"', self.almacenamiento)
        self.assertIn("verbo = Verbo.ABRIR", self.almacenamiento)
        self.assertIn("Verbo.CERRAR", self.almacenamiento)
        self.assertIn('nombre_objeto = "cajón"', self.almacenamiento)
        self.assertIn("CollisionShape3D.new()", self.almacenamiento)
        self.assertIn('cajon.name = "CajonCasa"', self.almacenamiento)
        self.assertIn("_cajon.position = POS_ABIERTO", self.almacenamiento)

    def test_almacenamiento_conecta_carried_y_home_storage_sin_estado_global(self):
        self.assertIn("func guardar_objeto(", self.almacenamiento)
        self.assertIn("func sacar_objeto(", self.almacenamiento)
        self.assertIn("func contenido(", self.almacenamiento)
        self.assertIn("Inventario.guardar_en_casa(", self.almacenamiento)
        self.assertIn("Inventario.sacar_de_casa(", self.almacenamiento)
        self.assertIn("Inventario.HOME_STORAGE", self.almacenamiento)
        self.assertIn("if not _abierto", self.almacenamiento)
        self.assertNotIn("Jornada.actual", self.almacenamiento)
        self.assertNotIn("Partida", self.almacenamiento)

    def test_almacenamiento_y_distribucion_funcionan_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importacion = subprocess.run([motor, "--headless", "--path", str(ROOT / "godot"), "--editor", "--import", "--quit"], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60, check=False)
        self.assertEqual(importacion.returncode, 0, importacion.stdout)
        resultado = subprocess.run([motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30, check=False)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 40, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_interacciones_domesticas_no_acoplan_partida_global(self):
        combinado = self.utileria + self.lampara + self.televisor + self.portatil + self.almacenamiento
        for termino in ("Partida", "Jornada.actual", "pistas_descubiertas"):
            self.assertNotIn(termino, combinado)

    def test_no_introduce_assets_externos(self):
        combinado = self.utileria + self.lampara + self.televisor + self.portatil + self.almacenamiento
        for termino in ("preload(", ".glb", ".png"):
            self.assertNotIn(termino, combinado)
        for linea in combinado.splitlines():
            if "load(" in linea:
                self.assertIn("res://arte/props_originales_98/", linea)
                self.assertIn(".obj", linea)


if __name__ == "__main__":
    unittest.main()
