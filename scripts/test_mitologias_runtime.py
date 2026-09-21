import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
DATOS = ROOT / "godot" / "datos" / "mitologias_runtime.json"
RUNTIME = ROOT / "godot" / "guion" / "mitologias_runtime.gd"
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
CIELOS = ROOT / "godot" / "guion" / "sueno_cielos.gd"
SIMBOLICO = ROOT / "godot" / "guion" / "juicio_simbolico.gd"
SIMBOLICO_3D = ROOT / "godot" / "guion" / "juicio_simbolico_3d.gd"

EJES = {
    "order-chaos",
    "creation-destruction",
    "light-shadow",
    "active-receptive",
    "individual-collective",
    "ascent-descent",
    "stasis-transformation",
    "voluntary-fated",
}


class MitologiasRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.datos = json.loads(DATOS.read_text(encoding="utf-8"))
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.cielos = CIELOS.read_text(encoding="utf-8")
        cls.simbolico = SIMBOLICO.read_text(encoding="utf-8")
        cls.simbolico_3d = SIMBOLICO_3D.read_text(encoding="utf-8")

    def test_toda_familia_onirica_tiene_entrada_runtime(self) -> None:
        bloque = re.search(
            r"const MITOS_VALIDOS := \[(.*?)\]\n",
            self.semillas,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(bloque)
        familias = set(re.findall(r'"([^"]+)"', bloque.group(1)))
        self.assertEqual(familias, set(self.datos["familias"]))

    def test_perfiles_acp_tienen_ocho_ejes_acotados(self) -> None:
        for nombre, tradicion in self.datos["tradiciones"].items():
            with self.subTest(tradicion=nombre):
                self.assertGreater(tradicion["muestra_acp"], 0)
                ejes = tradicion["ejes_medios"]
                self.assertEqual(EJES, set(ejes))
                for valor in ejes.values():
                    self.assertGreaterEqual(valor, 0.0)
                    self.assertLessEqual(valor, 1.0)

    def test_no_mezcla_akan_ni_mari_con_un_corpus_distinto(self) -> None:
        for familia in ("anansi_akan", "mari"):
            self.assertIn("sin_perfil_acp", self.datos["familias"][familia])
        self.assertNotIn("akan", self.datos["tradiciones"])
        self.assertNotIn("basque", self.datos["tradiciones"])

    def test_referencias_directas_solo_cuando_existen_en_el_corpus(self) -> None:
        esperadas = {
            "gilgamesh": "arch:ME-GILGAMESH",
            "baba_yaga": "arch:SL-BABA-YAGA",
            "maui_tamanuitera": "arch:PL-MAUI",
            "popol_wuj": "arch:MA-HERO-TWINS",
        }
        for familia, referencia in esperadas.items():
            self.assertEqual(
                referencia,
                self.datos["familias"][familia]["acp_directo"],
            )

    def test_runtime_no_controla_progreso(self) -> None:
        self.assertIn("class_name MitologiasRuntime", self.runtime)
        self.assertIn("FileAccess.get_file_as_string", self.runtime)
        self.assertIn("JSON.parse_string", self.runtime)
        self.assertIn("modular_cielo", self.runtime)
        self.assertIn("modulacion_juicio", self.runtime)
        self.assertNotIn("activar_semilla_onirica", self.runtime)
        self.assertNotIn("jornada", self.runtime.lower())

    def test_cielo_aplica_acp_antes_de_capas_externas(self) -> None:
        llamada = "MitologiasRuntime.modular_cielo(familia, resultado)"
        self.assertIn(llamada, self.cielos)
        self.assertLess(
            self.cielos.index(llamada),
            self.cielos.index("capas.sort_custom"),
        )

    def test_juicio_expone_y_materializa_el_perfil_runtime(self) -> None:
        self.assertIn("MitologiasRuntime.familia(id_mito)", self.simbolico)
        self.assertIn("MitologiasRuntime.ejes(id_mito)", self.simbolico)
        self.assertIn("MitologiasRuntime.modulacion_juicio(mito_id)", self.simbolico_3d)
        self.assertIn('set_meta("acp_ejes"', self.simbolico_3d)
        self.assertIn('set_meta("tradicion"', self.simbolico_3d)


if __name__ == "__main__":
    unittest.main()
