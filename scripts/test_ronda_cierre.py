from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULO = ROOT / "godot" / "guion" / "ronda_cierre.gd"


class RondaCierreTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODULO.read_text(encoding="utf-8")

    def test_declara_ruta_determinista_de_tres_a_cinco_puntos(self):
        self.assertIn("static func ruta_para", self.texto)
        self.assertIn("var cantidad := 3 + posmod(dia + raiz, 3)", self.texto)
        self.assertIn("cantidad = mini(cantidad, disponibles.size())", self.texto)
        self.assertNotIn("rand", self.texto.lower())

    def test_cunado_es_opcional(self):
        self.assertIn('const PUNTO_CUNADO := "despedir_cunado"', self.texto)
        self.assertIn("if cunado_presente:", self.texto)
        self.assertIn("disponibles.append(PUNTO_CUNADO)", self.texto)

    def test_progreso_es_idempotente_y_abandonable(self):
        self.assertIn("if completados.has(punto):\n\t\treturn true", self.texto)
        self.assertIn("static func abandonar", self.texto)
        self.assertIn('estado["abandonada"] = true', self.texto)

    def test_rangos_del_issue(self):
        for rango in ["incompleta", "correcta", "impecable", "abandonada"]:
            self.assertIn(f'"{rango}"', self.texto)

    def test_no_toca_recompensas_ni_progreso_global(self):
        bloque = self.texto.lower()
        for termino in [
            "dinero",
            "pistas_descubiertas",
            "vidas",
            "gastar_accion",
            "fichar_salida",
            "partida.",
            "jornada.",
        ]:
            self.assertNotIn(termino, bloque)

    def test_catalogo_contiene_los_puntos_fisicos_base(self):
        for punto in [
            "recoger_a7",
            "apagar_lampara",
            "cerrar_puerta",
            "revisar_bandeja",
            "devolver_carpeta",
            "comprobar_tablon",
        ]:
            self.assertIn(f'"{punto}"', self.texto)


if __name__ == "__main__":
    unittest.main()
