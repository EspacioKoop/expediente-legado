from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MONTAJE = RAIZ / "godot" / "guion" / "cuadros_oficina.gd"
CONTROLADOR = RAIZ / "godot" / "guion" / "dia_oficina_utileria_app.gd"


class CuadrosOficinaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.montaje = MONTAJE.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")

    def test_declara_tres_laminas_distintas(self):
        nombres = re.findall(r'"textura": "(cuadro-piramide-\d{2}\.png)"', self.montaje)
        self.assertEqual(
            nombres,
            [
                "cuadro-piramide-01.png",
                "cuadro-piramide-02.png",
                "cuadro-piramide-03.png",
            ],
        )

    def test_centros_quedan_a_altura_de_ojo(self):
        alturas = [
            float(valor)
            for valor in re.findall(
                r'"pos": Vector3\([^,]+,\s*([0-9.]+),\s*[^)]+\)', self.montaje
            )
        ]
        self.assertEqual(len(alturas), 3)
        self.assertTrue(all(1.7 <= altura <= 2.1 for altura in alturas))

    def test_montaje_consumidor_del_contrato_y_tolerante_a_fallos(self):
        self.assertIn("Cuadros.materializar(declaracion)", self.montaje)
        self.assertIn('datos["color_fallback"]', self.montaje)
        self.assertIn('if bool(datos["usar_textura"]):', self.montaje)
        self.assertIn('if textura != null:', self.montaje)
        self.assertIn("_marco(soporte, tam)", self.montaje)

    def test_lamina_tiene_uv_propias_y_no_colision(self):
        self.assertIn("QuadMesh.new()", self.montaje)
        self.assertNotIn("CollisionShape3D", self.montaje)
        self.assertNotIn("TexturaProcedural", self.montaje)

    def test_montaje_es_idempotente_y_solo_se_conecta_en_archivo(self):
        self.assertIn('mundo.has_node("CuadrosOficina")', self.montaje)
        self.assertEqual(self.controlador.count("CuadrosOficina.montar(mundo)"), 1)
        self.assertIn('if String(dia.jornada.get("fase", "")) == "archivo":', self.controlador)


if __name__ == "__main__":
    unittest.main()
