from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "godot" / "guion" / "dia_aviones_papel_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


def sin_comentarios(fuente):
    return "\n".join(linea.split("#", 1)[0] for linea in fuente.splitlines())


class AvionesPapelIntegracionDiaTest(unittest.TestCase):
    def setUp(self):
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.dia = DIA.read_text(encoding="utf-8")
        self.textos = TEXTOS.read_text(encoding="utf-8")

    def test_dia_monta_el_controller(self):
        self.assertIn('path="res://guion/dia_aviones_papel_app.gd"', self.dia)
        self.assertIn('[node name="AvionesPapelController"', self.dia)

    def test_oferta_tiene_rotulo_traducible(self):
        self.assertIn('AVIONES_TITULO,Aviones de papel', self.textos)
        self.assertIn('tr("AVIONES_TITULO")', self.controller)

    def test_reutiliza_disponibilidad_y_escena_de_jornada(self):
        self.assertIn(
            'preload("res://escenas/minijuego_aviones_papel_jornada.tscn")',
            self.controller,
        )
        self.assertIn("AvionesPapelDescanso.disponible(dia.jornada)", self.controller)
        self.assertIn('sesion.call("configurar_jornada", dia.jornada)', self.controller)
        self.assertIn('connect("finalizada", Callable(self, "_al_terminar"))', self.controller)

    def test_oferta_es_fisica_y_no_consume_hasta_jugar(self):
        self.assertIn("var oferta := Interactuable3D.new()", self.controller)
        self.assertIn("POSICION_OFERTA", self.controller)
        codigo = sin_comentarios(self.controller)
        self.assertNotIn("AvionesPapelDescanso.marcar_jugado", codigo)

    def test_pausa_no_toca_economia_ni_sellos(self):
        codigo = sin_comentarios(self.controller)
        for prohibido in (
            "Jornada.gastar_accion",
            'jornada["acciones"]',
            'jornada["dinero"]',
            "Sellos.registrar_sello",
            "registrar_sello(",
        ):
            self.assertNotIn(prohibido, codigo)

    def test_restaura_control_y_presenta_comentario_seguro(self):
        self.assertIn("Node.PROCESS_MODE_DISABLED", self.controller)
        self.assertIn("Input.MOUSE_MODE_VISIBLE", self.controller)
        self.assertIn("_restaurar_presentacion()", self.controller)
        self.assertIn('resultado.get("descanso", {})', self.controller)


if __name__ == "__main__":
    unittest.main()
