from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
CIELOS = ROOT / "godot" / "guion" / "sueno_cielos.gd"
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
DIA_CIELO = ROOT / "godot" / "guion" / "dia_cielo_app.gd"


class SuenoCielosTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.cielos = CIELOS.read_text(encoding="utf-8")
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.dia = DIA_CIELO.read_text(encoding="utf-8")

    def test_todas_las_familias_oniricas_tienen_perfil(self) -> None:
        bloque = re.search(
            r"const MITOS_VALIDOS := \[(.*?)\]\n",
            self.semillas,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(bloque)
        familias = re.findall(r'"([^"]+)"', bloque.group(1))
        self.assertGreaterEqual(len(familias), 12)
        for familia in familias:
            with self.subTest(familia=familia):
                self.assertRegex(
                    self.cielos,
                    rf'(?m)^\s*"{re.escape(familia)}":\s*$',
                )

    def test_el_cielo_usa_la_misma_seleccion_y_asignacion_que_los_mitos(self) -> None:
        self.assertIn("SemillasOniricas", self.dia)
        self.assertIn("seleccionar_para_noche(", self.dia)
        self.assertIn("MitologiasNoche.MAX_FAMILIAS_NOCHE", self.dia)
        self.assertIn("SuenoCielos", self.dia)
        self.assertIn("familia_para_escena(", self.dia)
        self.assertIn("pendientes.size()", self.dia)

    def test_cada_entrada_restaurara_el_preset_antes_de_modular(self) -> None:
        self.assertIn("_restaurar_cielo_siga()", self.dia)
        self.assertIn("CIELO_SIGA.duplicate()", self.dia)
        self.assertIn('if fase != "sueño":', self.dia)
        self.assertIn("SuenoCielos.componer(", self.dia)
        self.assertIn("SuenoCielos.aplicar(material, perfil)", self.dia)

    def test_compositor_acepta_capas_externas_sin_segunda_fuente_de_verdad(self) -> None:
        self.assertIn("PARAMETROS_VALIDOS", self.cielos)
        self.assertIn('capa.get("parametros", {})', self.cielos)
        self.assertIn("PRIORIDAD_EXTERNA_DEFECTO", self.cielos)
        self.assertIn("_comparar_modificadores", self.cielos)
        self.assertIn('get("prioridad"', self.cielos)
        self.assertIn('get("origen"', self.cielos)
        self.assertIn("capas.sort_custom", self.cielos)
        self.assertIn("PARAMETROS_VALIDOS.has(clave)", self.cielos)

    def test_religion_tarot_e_ideologia_son_modificadores_no_familias(self) -> None:
        self.assertIn("religión, Tarot, ideología", self.cielos)
        self.assertIn("religion:<id>:practica", self.cielos)
        self.assertIn("tarot:<id>", self.cielos)
        self.assertIn("ideologia:<tag>", self.cielos)
        self.assertIn("_modificadores_cielo_sueno()", self.dia)
        self.assertIn('const RELIGION_SUENO := preload("res://guion/religion_sueno_935.gd")', self.dia)
        self.assertRegex(self.dia, r"RELIGION_SUENO\s*\.\s*modificadores\(")
        # El runtime consume el contrato común; no inventa flags de creencia.
        self.assertNotIn("religion_fe", self.dia)
        self.assertNotIn("religiosidad", self.dia)
        self.assertNotIn("ideologia_", self.dia)
        self.assertNotIn("tarot_", self.dia)

    def test_perfiles_cubren_direcciones_visuales_distintas(self) -> None:
        # Gates mínimos para evitar que el catálogo se degrade a doce aliases.
        for fragmento in (
            '"duat":',
            '"bandas": 28.0',
            '"dragon_japones":',
            '"luna_halo": 0.18',
            '"mari":',
            '"nubes": 0.92',
            '"maui_tamanuitera":',
            '"ocaso_mezcla": 0.62',
            '"yggdrasil":',
            '"via_lactea": 0.20',
        ):
            self.assertIn(fragmento, self.cielos)


if __name__ == "__main__":
    unittest.main()
