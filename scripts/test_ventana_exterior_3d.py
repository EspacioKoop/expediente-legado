from pathlib import Path
import hashlib
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
EXTERIOR = ROOT / "godot" / "guion" / "ventana_exterior_3d.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_ventana_clima_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
ASSET = ROOT / "godot" / "assets" / "texturas" / "ventana_casa_ai_98" / "fondo_barrio_98.webp"
PROCEDENCIA = ROOT / "godot" / "assets" / "procedencia.json"


class VentanaExterior3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.exterior = EXTERIOR.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.registro = json.loads(PROCEDENCIA.read_text(encoding="utf-8"))

    def test_es_diorama_hibrido_en_un_unico_subviewport(self):
        self.assertEqual(self.exterior.count("SubViewport.new()"), 1)
        self.assertIn("Camera3D.new()", self.exterior)
        self.assertIn("MeshInstance3D.new()", self.exterior)
        self.assertIn("BoxMesh.new()", self.exterior)
        self.assertIn("CylinderMesh.new()", self.exterior)
        self.assertIn("SphereMesh.new()", self.exterior)
        self.assertIn("QuadMesh.new()", self.exterior)
        self.assertIn("TAM_VIEWPORT := Vector2i(320, 180)", self.exterior)
        self.assertIn("TEXTURE_FILTER_NEAREST", self.exterior)
        self.assertIn("FONDO_BARRIO_98", self.exterior)
        self.assertIn('name = "FondoBarrioFotorealista98"', self.exterior)

    def test_el_matte_reemplaza_la_linea_de_bloques_sin_perder_primer_termino_3d(self):
        inicio = self.exterior.index("func _montar_barrio")
        fin = self.exterior.index("func _montar_fondo_barrio")
        montaje = self.exterior[inicio:fin]
        self.assertIn("_montar_fondo_barrio(raiz)", montaje)
        self.assertNotIn("_montar_edificio(", montaje)
        self.assertIn("_montar_coche(", montaje)
        self.assertIn("_montar_arbol(", montaje)
        self.assertIn("_montar_farola(", montaje)
        self.assertIn('fondo.position = Vector3(0.0, 4.65, -24.5)', self.exterior)

    def test_matte_propietario_tiene_procedencia_hash_y_tamano_acotado(self):
        self.assertTrue(ASSET.is_file())
        self.assertLess(ASSET.stat().st_size, 10 * 1024)
        esperado = hashlib.sha256(ASSET.read_bytes()).hexdigest()
        ficha = next(
            a for a in self.registro["assets"]
            if a["ruta"] == "texturas/ventana_casa_ai_98/fondo_barrio_98.webp"
        )
        self.assertEqual(esperado, ficha["sha256"])
        self.assertEqual(
            esperado,
            "9a12e2a07eeb237a64a6f43fbb6e70d56616076ad75c3b31fce00f026d3e9883",
        )

    def test_cubre_los_cinco_estados_del_clima_y_tinta_el_matte(self):
        for estado in ("Clima.DESPEJADO", "Clima.NUBLADO", "Clima.LLUVIA", "Clima.NIEBLA", "Clima.NIEVE"):
            self.assertIn(estado, self.exterior)
        self.assertIn("GPUParticles3D.new()", self.exterior)
        self.assertIn('name = "Lluvia3D"', self.exterior)
        self.assertIn('name = "Nieve3D"', self.exterior)
        self.assertIn('name = "BancosNiebla3D"', self.exterior)
        self.assertIn('name = "Nubes3D"', self.exterior)
        self.assertGreaterEqual(self.exterior.count("_tintar_fondo(Color("), 5)
        self.assertIn("_fondo_material.albedo_color = color", self.exterior)

    def test_la_casa_no_se_convierte_en_exterior(self):
        self.assertIn('dia.jornada.get("fase", "")', self.controlador)
        self.assertIn('!= "casa"', self.controlador)
        self.assertIn('Clima.estado(int(dia.jornada.get("dia", 1)))', self.controlador)
        self.assertIn('get_node_or_null("VentanaCasa")', self.controlador)
        self.assertNotIn('"exterior"', self.controlador)

    def test_el_controlador_esta_montado_en_dia(self):
        self.assertIn('res://guion/dia_ventana_clima_app.gd', self.dia)
        self.assertIn('[node name="VentanaClimaController"', self.dia)


if __name__ == "__main__":
    unittest.main()
