from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "dialogo_archivado_companeros.gd"
SESION = ROOT / "godot" / "guion" / "dia_archivado_app.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_dialogo_archivado_965.gd"


class DialogoArchivado965Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modelo = MODELO.read_text(encoding="utf-8")
        cls.sesion = SESION.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")
        cls.prueba = PRUEBA.read_text(encoding="utf-8")

    def test_modelo_es_puro_y_acotado(self):
        self.assertIn("class_name DialogoArchivadoCompaneros", self.modelo)
        self.assertIn("const UMBRAL_ALTO := 3", self.modelo)
        self.assertIn("static func resolver(", self.modelo)
        for forbidden in ("Partida.", "Jornada.", "FileAccess", "guardar", "registrar_respuesta"):
            self.assertNotIn(forbidden, self.modelo)

    def test_sesion_expone_solo_el_estado_derivado(self):
        self.assertIn("func desorden_total() -> int:", self.sesion)
        self.assertIn("ArchivadoBandeja.desorden_por_destino(_estado_archivado)", self.sesion)
        bloque = self.sesion.split("func desorden_total() -> int:", 1)[1].split("\n\n", 1)[0]
        self.assertNotIn("_persistir(", bloque)
        self.assertNotIn("_guardar(", bloque)

    def test_prioridad_contextual_no_tapa_reacciones_especificas(self):
        religion = self.dia.index("DialogoReligion933.resolver_clave")
        social = self.dia.index("DialogoIdeologico.resolver_companero")
        archivo = self.dia.index("DialogoArchivadoCompaneros.resolver")
        hora = self.dia.index("DialogoHorarioCompaneros.resolver")
        self.assertLess(religion, social)
        self.assertLess(social, archivo)
        self.assertLess(archivo, hora)
        self.assertIn("_archivado_sesion.desorden_total()", self.dia)

    def test_copy_existe_para_cuatro_companeros_y_dos_niveles(self):
        for actor in ("CUNADO", "BECARIO", "JUBILACION", "RIEGOS"):
            for nivel in ("LEVE", "ALTO"):
                self.assertIn(f"COMPA_ARCHIVO_{actor}_{nivel},", self.textos)

    def test_regresion_cubre_reversibilidad(self):
        self.assertIn("sin desorden conserva el diálogo base", self.prueba)
        self.assertIn("tres errores cruzan el umbral alto", self.prueba)
        self.assertIn("corregir el caso elimina también la reacción narrativa", self.prueba)


if __name__ == "__main__":
    unittest.main()
