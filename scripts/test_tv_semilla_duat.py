import json
from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
TV = RAIZ / "godot" / "guion" / "television_interactiva_3d.gd"
DUAT = RAIZ / "godot" / "guion" / "sueno_duat.gd"
CASA = RAIZ / "godot" / "guion" / "casa_utileria.gd"
CATALOGO_TV = RAIZ / "godot" / "datos" / "tv_domestica_98.json"


class TvSemillaDuatTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tv = TV.read_text(encoding="utf-8")
        cls.duat = DUAT.read_text(encoding="utf-8")
        cls.casa = CASA.read_text(encoding="utf-8")
        cls.catalogo_tv = json.loads(CATALOGO_TV.read_text(encoding="utf-8"))

    def test_usa_el_televisor_real_de_casa(self):
        self.assertIn("TelevisionInteractiva3D.new()", self.casa)
        self.assertIn('televisor.name = "TelevisorCasaInteractuable"', self.casa)
        self.assertIn("activado.connect(_interactuar_directo)", self.tv)

    def test_encender_o_usar_mando_no_activa_semilla(self):
        mando = self.tv.split("func alternar_desde_mando()", 1)[1].split(
            "func _interactuar_directo", 1
        )[0]
        alternar = self.tv.split("func _alternar(", 1)[1].split(
            "func _jornada_en_escena", 1
        )[0]
        self.assertIn("_alternar(null)", mando)
        self.assertNotIn("registrar_documental", mando)
        self.assertNotIn("SemillasOniricas", mando)
        self.assertNotIn("registrar_exposicion_de_bloque", mando)
        self.assertNotIn("registrar_documental", alternar)
        self.assertNotIn("SemillasOniricas", alternar)
        self.assertNotIn("registrar_exposicion_de_bloque", alternar)

    def test_fragmento_exige_seleccion_y_final_del_contenido(self):
        directo = self.tv.split("func _interactuar_directo", 1)[1].split(
            "func _alternar(", 1
        )[0]
        self.assertIn("if not _encendida:", directo)
        self.assertIn("if _paso_documental == 0:", directo)
        self.assertIn("_paso_documental = 1", directo)
        self.assertIn("var jornada_actual := _jornada_en_escena()", directo)
        self.assertIn(
            "SuenoDuat.registrar_documental(jornada_actual, true)", directo
        )
        self.assertIn("_activar_exposicion_tv(jornada_actual)", directo)

    def test_apagar_interrumpe_fragmento_incompleto(self):
        alternar = self.tv.split("func _alternar(", 1)[1].split(
            "func _jornada_en_escena", 1
        )[0]
        self.assertIn("if not _encendida and not _documental_completado:", alternar)
        self.assertIn("_paso_documental = 0", alternar)

    def test_duat_conserva_el_contrato_comun_de_442(self):
        self.assertIn('const ID := "duat"', self.duat)
        self.assertIn('const FUENTE_TV := "tv:microdocumental_excavaciones_98"', self.duat)
        self.assertIn("if not fragmento_completado:", self.duat)
        self.assertIn(
            "SemillasOniricas.activar_semilla_onirica(jornada, ID, FUENTE_TV, 1)",
            self.duat,
        )


    def test_tv_registra_exposicion_solo_desde_un_bloque_declarado(self):
        bloques = self.catalogo_tv["bloques"]
        self.assertTrue(bloques)
        boletin = bloques[0]["boletin"]
        self.assertEqual(boletin["hecho_id"], "turnos-atencion-planta4")
        exposicion = boletin["exposicion_ideologica"]
        self.assertTrue(exposicion["id"].startswith("tv:"))
        self.assertTrue(exposicion["fuente"].startswith("tv:"))
        self.assertIn(exposicion["eje"], {
            "comunismo",
            "socialdemocrata",
            "centrista",
            "neoliberal",
        })
        self.assertIn("registrar_exposicion_de_bloque", self.tv)
        self.assertIn("Prometeo", self.tv)
        self.assertNotIn("registrar_eleccion_ideologica(", self.tv)

    def test_no_hay_hud_de_desbloqueo(self):
        texto = self.tv.lower()
        for termino in ["desbloqueado", "unlock", "hudlayer", "semilla activada"]:
            self.assertNotIn(termino, texto)

    def test_no_acopla_utileria_al_estado_global(self):
        self.assertNotIn("partida.estado", self.tv)
        self.assertNotIn("Jornada.", self.tv)
        self.assertIn("get_property_list()", self.tv)
        self.assertIn('String(propiedad.get("name", "")) != "jornada"', self.tv)


if __name__ == "__main__":
    unittest.main()
