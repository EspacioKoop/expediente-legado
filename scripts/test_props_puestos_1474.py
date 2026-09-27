from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
UTILERIA = ROOT / "godot" / "guion" / "oficina_utileria.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"


class PropsPuestos1474Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.espacio = ESPACIO.read_text(encoding="utf-8")

    def test_vocabulario_supera_diez_props_reutilizables(self) -> None:
        funciones = re.findall(r"^static func (agregar_[a-z_]+)\(", self.utileria, re.MULTILINE)
        props = {nombre for nombre in funciones if nombre != "agregar_taza"}
        self.assertGreaterEqual(len(props), 12)
        for esperado in (
            "agregar_portalapices",
            "agregar_agenda",
            "agregar_libreta",
            "agregar_caja_personal",
            "agregar_calculadora",
            "agregar_funda_gafas",
            "agregar_planta",
            "agregar_llavero",
            "agregar_termo",
            "agregar_sobre",
            "agregar_sello",
            "agregar_regla",
            "agregar_cuaderno_dibujo",
        ):
            self.assertIn(esperado, props)

    def test_perfiles_historicos_se_apoyan_en_ids_canonicos(self) -> None:
        for identidad in ("emperador", "aduanero_ny", "correspondencia", "riegos", "fielato"):
            self.assertIn(f'"{identidad}":', self.utileria)
        self.assertIn('"correspondencia": ["sobre", "agenda", "portalapices"]', self.utileria)
        self.assertIn('"riegos": ["regla", "calculadora", "libreta"]', self.utileria)
        self.assertIn('"fielato": ["cuaderno_dibujo", "portalapices", "agenda"]', self.utileria)

    def test_identidad_viaja_del_roster_al_cuerpo_3d(self) -> None:
        self.assertIn('"id_companero": String(quien.get("id", ""))', self.dia)
        self.assertIn('cuerpo.set_meta("companero_id", id_companero)', self.espacio)
        self.assertIn('nodo.has_meta("companero_id")', self.utileria)
        self.assertIn('id == "cunado"', self.utileria)

    def test_hay_composiciones_neutras_deterministas(self) -> None:
        self.assertIn("const PERFILES_NEUTROS := [", self.utileria)
        self.assertGreaterEqual(self.utileria.count('["'), 4)
        self.assertIn("indice % PERFILES_NEUTROS.size()", self.utileria)
        self.assertIn('puesto.set_meta("perfil_props"', self.utileria)

    def test_props_no_introducen_texto_legible_ni_interaccion(self) -> None:
        for token in ("Label3D.new()", "Label.new()", "Button.new()", "Area3D.new()", "CollisionShape3D.new()"):
            self.assertNotIn(token, self.utileria)

    def test_materiales_siguen_shader_visual_del_espacio(self) -> None:
        self.assertIn("material.shader = load(Espacio3D.shader_del_sitio())", self.utileria)
        self.assertIn('material.set_shader_parameter("color_base", color)', self.utileria)
        self.assertNotIn("StandardMaterial3D.new()", self.utileria)

    def test_ranuras_quedan_al_fondo_del_escritorio(self) -> None:
        bloque = self.utileria.split("const RANURAS_PROPS := [", 1)[1].split("]", 1)[0]
        zs = [float(valor) for valor in re.findall(r"Vector3\([^,]+,\s*[^,]+,\s*(-?\d+\.\d+)\)", bloque)]
        self.assertEqual(len(zs), 3)
        self.assertTrue(all(z <= -0.30 for z in zs))


if __name__ == "__main__":
    unittest.main()
