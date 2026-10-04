from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
ARPIA = ROOT / "godot/guion/juicio_combate_arpia_3d.gd"


class Arpia2087Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = ARPIA.read_text(encoding="utf-8")
        cls.codigo_sin_comentarios = "\n".join(
            linea
            for linea in cls.codigo.splitlines()
            if not linea.lstrip().startswith("#")
        )

    def test_reutiliza_hostigador_sin_duplicar_mecanica(self):
        for estado in (
            "ARQUETIPOS.TELEGRAFIAR",
            "ARQUETIPOS.DISPARAR_LINEA",
            "ARQUETIPOS.VULNERABLE",
        ):
            with self.subTest(estado=estado):
                self.assertIn(estado, self.codigo)

        for prohibido in (
            "ARQUETIPOS.avanzar(",
            "JuicioCombateHostigador3D.avanzar(",
            "HOSTIGADOR.avanzar(",
            "_aplicar_impacto_rival",
            "impacto_linea(",
            "resultado_ataque_rival",
            "move_and_slide(",
            "velocity =",
            "Partida.",
            "Jornada.",
            "loot",
            "XP",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, self.codigo_sin_comentarios)

    def test_api_standalone_y_poses_de_picado(self):
        self.assertIn("static func montar(rival: Node3D) -> Dictionary:", self.codigo)
        self.assertIn("static func pintar(", self.codigo)
        self.assertIn("static func limpiar(presentacion: Dictionary) -> void:", self.codigo)
        self.assertIn('"ArpiaHostigadora"', self.codigo)
        self.assertIn('"AlaIzq"', self.codigo)
        self.assertIn('"AlaDer"', self.codigo)

        bloque_telegraph = self._bloque_estado("ARQUETIPOS.TELEGRAFIAR")
        bloque_ataque = self._bloque_estado("ARQUETIPOS.DISPARAR_LINEA")
        bloque_vulnerable = self._bloque_estado("ARQUETIPOS.VULNERABLE")

        self.assertIn("ALTURA_BASE + 0.22", bloque_telegraph)
        self.assertIn("deg_to_rad(-58.0)", bloque_telegraph)
        self.assertIn("deg_to_rad(58.0)", bloque_telegraph)

        self.assertIn("deg_to_rad(-32.0)", bloque_ataque)
        self.assertIn("deg_to_rad(-26.0)", bloque_ataque)
        self.assertIn("deg_to_rad(26.0)", bloque_ataque)

        self.assertIn("ALTURA_BASE - 0.08", bloque_vulnerable)
        self.assertIn("deg_to_rad(18.0)", bloque_vulnerable)
        self.assertIn("deg_to_rad(-78.0)", bloque_vulnerable)
        self.assertIn("deg_to_rad(78.0)", bloque_vulnerable)

    def test_reduccion_movimiento_solo_elimina_oscilacion_de_reposo(self):
        self.assertIn("reduccion_movimiento: bool", self.codigo)
        self.assertIn("if not reduccion_movimiento:", self.codigo)
        self.assertIn("Time.get_ticks_msec()", self.codigo)

        for estado in (
            "ARQUETIPOS.TELEGRAFIAR",
            "ARQUETIPOS.DISPARAR_LINEA",
            "ARQUETIPOS.VULNERABLE",
        ):
            bloque = self._bloque_estado(estado)
            self.assertNotIn("reduccion_movimiento", bloque)

        self.assertNotIn("Tween", self.codigo)
        self.assertNotIn("create_timer", self.codigo)
        self.assertNotIn("await ", self.codigo)

    def test_montar_y_limpiar_no_crean_estado_de_campana(self):
        self.assertIn("rival.add_child(raiz)", self.codigo)
        self.assertIn("raiz.queue_free()", self.codigo)
        self.assertIn("presentacion.clear()", self.codigo)
        self.assertNotIn("add_to_group", self.codigo_sin_comentarios)
        self.assertNotRegex(
            self.codigo_sin_comentarios,
            re.compile(r"\b(?:set_meta|get_meta)\("),
        )

    def _bloque_estado(self, estado: str) -> str:
        marcador = f"\t\t{estado}:"
        inicio = self.codigo.find(marcador)
        self.assertGreaterEqual(inicio, 0, estado)
        resto = self.codigo[inicio + len(marcador):]
        siguiente = resto.find("\n\t\tARQUETIPOS.")
        por_defecto = resto.find("\n\t\t_:")
        candidatos = [indice for indice in (siguiente, por_defecto) if indice >= 0]
        fin = min(candidatos) if candidatos else len(resto)
        return resto[:fin]


if __name__ == "__main__":
    unittest.main()
