from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
OBJETOS = ROOT / "godot" / "guion" / "objetos_oniricos.gd"
TV = ROOT / "godot" / "guion" / "television_interactiva_3d.gd"
DUAT = ROOT / "godot" / "guion" / "sueno_duat.gd"
INTERACCION = ROOT / "godot" / "guion" / "sueno_duat_interaccion_3d.gd"
NOCHE = ROOT / "godot" / "guion" / "dia_duat_sueno_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class DuatNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.objetos = OBJETOS.read_text(encoding="utf-8")
        cls.tv = TV.read_text(encoding="utf-8")
        cls.duat = DUAT.read_text(encoding="utf-8")
        cls.interaccion = INTERACCION.read_text(encoding="utf-8")
        cls.noche = NOCHE.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_reutiliza_memoria_generica_de_objetos_tocados(self):
        self.assertIn('const CLAVE := "objetos_tocados_sueno"', self.objetos)
        self.assertIn("static func para_pesaje(jornada: Dictionary)", self.objetos)
        self.assertIn('"televisor_casa": {"peso": 5.0, "peso_sellado": 4.0}', self.objetos)
        self.assertIn('"manipulado_hoy": true', self.objetos)

    def test_documental_registra_el_televisor_como_objeto_real(self):
        self.assertIn('const OBJETO_ONIRICO_ID := "televisor_casa"', self.tv)
        self.assertIn(
            "ObjetosOniricos.registrar(jornada_actual, OBJETO_ONIRICO_ID)", self.tv
        )
        self.assertIn(
            "SuenoDuat.registrar_documental(jornada_actual, true)", self.tv
        )

    def test_pesaje_admite_el_minimo_real_de_un_objeto(self):
        self.assertIn("if validos.is_empty():", self.duat)
        self.assertIn("if objetos.size() == 1:", self.duat)
        self.assertIn('unico.get("peso_sellado", peso_objetivo)', self.duat)
        self.assertNotIn("if validos.size() < 2:", self.duat)

    def test_noche_consume_selector_y_asignacion_comunes(self):
        self.assertIn("SemillasOniricas", self.noche)
        self.assertIn("seleccionar_para_noche", self.noche)
        self.assertIn("MitologiasNoche.MAX_FAMILIAS_NOCHE", self.noche)
        self.assertIn("corresponde_a_escena", self.noche)
        self.assertIn("SuenoDuatInteraccion3D.ID_MITO", self.noche)
        self.assertNotIn("activar_semilla_onirica", self.noche)

    def test_noche_usa_objetos_reales_y_vertical_interactivo(self):
        self.assertIn("ObjetosOniricos.para_pesaje(dia.jornada)", self.noche)
        self.assertIn("SuenoDuatInteraccion3D.new()", self.noche)
        self.assertIn("duat.configurar(objetos, dia._raiz(), reduccion)", self.noche)
        self.assertIn("PreferenciasSiga.cargar()", self.noche)
        self.assertIn("_ancla_entre_entrada_y_salida", self.noche)
        self.assertNotIn("mundo.queue_free", self.noche)
        self.assertIn("Interactuable3D.new()", self.interaccion)

    def test_dia_monta_controller_duat(self):
        self.assertIn('path="res://guion/dia_duat_sueno_app.gd"', self.dia)
        self.assertIn(
            '[node name="DuatSuenoController" type="Node" parent="."]', self.dia
        )


if __name__ == "__main__":
    unittest.main()
