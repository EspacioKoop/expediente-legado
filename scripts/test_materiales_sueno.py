from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
FORMAS = RAIZ / "godot" / "guion" / "sueno_formas.gd"
SUENO = RAIZ / "godot" / "guion" / "sueno.gd"
ESPACIO = RAIZ / "godot" / "guion" / "espacio_3d.gd"
SHADER = RAIZ / "godot" / "arte" / "psx.gdshader"
PROCEDURAL = RAIZ / "godot" / "guion" / "textura_procedural.gd"

IDS = ("crucero", "patio", "peine", "escalera", "embudo", "gilgamesh")
MATERIALES_DESPIERTOS = {
    "linoleo",
    "gotele",
    "techo",
    "moqueta",
    "asfalto",
    "revoco_urbano",
    "melamina",
    "metal_pintado",
    "plastico_abs",
    "madera_domestica",
    "tejido_domestico",
    "acero_cocina",
}


class MaterialesSuenoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.formas = FORMAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.espacio = ESPACIO.read_text(encoding="utf-8")
        cls.shader = SHADER.read_text(encoding="utf-8")
        cls.procedural = PROCEDURAL.read_text(encoding="utf-8")

    def _bloque(self, indice):
        inicio = self.formas.index(f'\t"{IDS[indice]}":')
        if indice + 1 < len(IDS):
            fin = self.formas.index(f'\t"{IDS[indice + 1]}":', inicio)
        else:
            fin = self.formas.index("\n}\n\n\nstatic func ids()", inicio)
        return self.formas[inicio:fin]

    def test_cada_forma_reutiliza_materiales_del_mundo_despierto(self):
        for i, forma_id in enumerate(IDS):
            bloque = self._bloque(i)
            with self.subTest(forma=forma_id):
                suelo = re.search(r'"textura_suelo": "([^"]+)"', bloque)
                muro = re.search(r'"textura_muro": "([^"]+)"', bloque)
                self.assertIsNotNone(suelo)
                self.assertIsNotNone(muro)
                self.assertIn(suelo.group(1), MATERIALES_DESPIERTOS)
                self.assertIn(muro.group(1), MATERIALES_DESPIERTOS)

    def test_cada_forma_deforma_la_escala_por_ejes(self):
        for i, forma_id in enumerate(IDS):
            bloque = self._bloque(i)
            with self.subTest(forma=forma_id):
                match = re.search(
                    r'"deformacion_textura": Vector3\(([^)]+)\)',
                    bloque,
                )
                self.assertIsNotNone(match)
                valores = [float(v.strip()) for v in match.group(1).split(",")]
                self.assertEqual(len(valores), 3)
                self.assertGreater(len({round(abs(v), 3) for v in valores}), 1)

    def test_la_luz_espacial_preserva_legibilidad_material(self):
        energia = re.search(
            r"const ENERGIA_LUZ_MATERIAL := ([0-9.]+)",
            self.formas,
        )
        alcance = re.search(
            r"const ALCANCE_LUZ_MATERIAL := ([0-9.]+)",
            self.formas,
        )
        self.assertIsNotNone(energia)
        self.assertIsNotNone(alcance)
        self.assertGreaterEqual(float(energia.group(1)), 4.0)
        self.assertGreaterEqual(float(alcance.group(1)), 18.0)
        self.assertEqual(
            len(re.findall(r'"energia":\s*ENERGIA_LUZ_MATERIAL', self.formas)),
            len(IDS),
        )
        self.assertEqual(
            len(re.findall(r'"alcance":\s*ALCANCE_LUZ_MATERIAL', self.formas)),
            len(IDS),
        )
        self.assertEqual(self.formas.count('"ambiente_energia": 0.42'), len(IDS))

    def test_el_contraste_onirico_refuerza_solo_el_fallback_procedural(self):
        constante = re.search(
            r"const CONTRASTE_MATERIAL_ONIRICO := ([0-9.]+)",
            self.formas,
        )
        self.assertIsNotNone(constante)
        self.assertGreaterEqual(float(constante.group(1)), 1.5)
        self.assertEqual(
            self.formas.count('"contraste_textura": CONTRASTE_MATERIAL_ONIRICO'),
            len(IDS),
        )
        self.assertIn(
            '"contraste_textura": forma.get("contraste_textura", 1.0)',
            self.sueno,
        )
        self.assertIn('espacio.get("contraste_textura", 1.0)', self.espacio)
        self.assertGreaterEqual(
            len(
                re.findall(
                    r"TexturaProcedural\.por_nombre\("
                    r"\s*textura\s*,\s*color\s*,\s*hash\(textura\)\s*,\s*contraste",
                    self.espacio,
                )
            ),
            2,
        )
        self.assertRegex(
            self.procedural,
            r"static func por_nombre\([\s\S]*?contraste: float = 1\.0",
        )
        self.assertIn(
            "return calculada(nombre, base, semilla, contraste)",
            self.procedural,
        )
        self.assertIn("_contrastar_textura(textura, base, contraste)", self.procedural)
        self.assertIn(
            "ResourceLoader.exists(ruta) and not _es_puntero_lfs(ruta)",
            self.procedural,
        )
        self.assertIn("return traida", self.procedural)
        self.assertLess(
            self.procedural.index("return traida"),
            self.procedural.index("return calculada(nombre, base, semilla, contraste)"),
        )
        self.assertIn("static func _es_puntero_lfs(", self.procedural)
        self.assertIn(
            '"version https://git-lfs.github.com/spec/v1".to_utf8_buffer()',
            self.procedural,
        )
        self.assertNotIn("get_string_from_utf8()", self.procedural)
        explicita = self.procedural.index('if nombre.begins_with("res://")')
        carga_explicita = self.procedural.index(
            'return ResourceLoader.load(nombre, "Texture2D") as Texture2D',
            explicita,
        )
        helper = self.procedural.index("static func _contrastar_textura")
        self.assertLess(carga_explicita, helper)

    def test_el_sueno_conserva_detalle_sin_cambiar_el_filtrado_normal(self):
        self.assertEqual(
            self.formas.count('"preservar_detalle_textura": true'),
            len(IDS),
        )
        self.assertIn(
            '"preservar_detalle_textura": forma.get("preservar_detalle_textura", false)',
            self.sueno,
        )
        self.assertIn(
            'espacio.get("preservar_detalle_textura", false)',
            self.espacio,
        )
        self.assertGreaterEqual(
            self.espacio.count(
                'set_shader_parameter("preservar_detalle_textura", preservar_detalle_textura)'
            ),
            1,
        )
        self.assertGreaterEqual(
            self.espacio.count('set_shader_parameter("textura_detalle", imagen)'),
            2,
        )
        self.assertIn(
            "filter_linear_mipmap_anisotropic",
            self.shader,
        )
        self.assertIn(
            "uniform sampler2D textura_detalle : source_color, filter_linear, repeat_enable",
            self.shader,
        )
        self.assertIn(
            "uniform bool preservar_detalle_textura = false;",
            self.shader,
        )
        self.assertIn("vec3 muestra_2d(vec2 uv)", self.shader)
        self.assertIn("return texture(textura_detalle, uv).rgb;", self.shader)
        bloque_planta = self.espacio[
            self.espacio.index("static func _por_planta(") : self.espacio.index("static func _suelo(")
        ]
        self.assertEqual(
            bloque_planta.count("preservar_detalle_textura"),
            4,
            "suelo, techo y muros deben heredar el sampler opt-in del espacio",
        )

    def test_hay_inversion_deliberada_en_al_menos_una_forma(self):
        vectores = re.findall(
            r'"deformacion_textura": Vector3\(([^)]+)\)',
            self.formas,
        )
        self.assertTrue(
            any(float(v.strip()) < 0.0 for vector in vectores for v in vector.split(",")),
            "el contrato de #399 contempla inversión deliberada, no solo repetición",
        )

    def test_el_runtime_propaga_el_warp_sin_afectar_el_default(self):
        self.assertIn(
            '"deformacion_textura": forma.get("deformacion_textura", Vector3.ONE)',
            self.sueno,
        )
        self.assertIn(
            'espacio.get("deformacion_textura", Vector3.ONE)',
            self.espacio,
        )
        self.assertGreaterEqual(
            self.espacio.count(
                'set_shader_parameter("deformacion_textura", deformacion)'
            ),
            2,
        )

    def test_el_shader_mantiene_el_mundo_normal_por_defecto(self):
        self.assertIn(
            "uniform vec3 deformacion_textura = vec3(1.0);",
            self.shader,
        )
        self.assertIn(
            "punto * escala_textura * deformacion_textura",
            self.shader,
        )


if __name__ == "__main__":
    unittest.main()
