from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CINEMATICA = RAIZ / "godot" / "guion" / "proyeccion_onirica_cinematica.gd"
CAPA = RAIZ / "godot" / "guion" / "visor_proyeccion_app.gd"
CAPA_COMBINACIONES = RAIZ / "godot" / "guion" / "visor_combinaciones_app.gd"
CAPA_ANOTACIONES = RAIZ / "godot" / "guion" / "visor_anotaciones_app.gd"
ESCENA_VISOR = RAIZ / "godot" / "escenas" / "visor.tscn"


class ProyeccionOniricaTest(unittest.TestCase):
    def setUp(self):
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")
        self.capa_combinaciones = CAPA_COMBINACIONES.read_text(encoding="utf-8")
        self.capa_anotaciones = CAPA_ANOTACIONES.read_text(encoding="utf-8")
        self.escena = ESCENA_VISOR.read_text(encoding="utf-8")

    def test_estados_tienen_identidad_estable(self):
        for estado in ("valida", "contaminada", "blanco", "caos"):
            self.assertIn(f'"{estado}"', self.cinematica)
        self.assertIn('return "proyeccion-onirica-%s" % estado', self.cinematica)

    def test_blanco_es_un_estado_y_no_un_fallo(self):
        self.assertIn("ESTADO_BLANCO", self.cinematica)
        self.assertIn("_pantalla_de(estado)", self.cinematica)
        self.assertNotIn("error", self.cinematica.lower())

    def test_la_cinematica_no_decide_reglas(self):
        for llamada in (
            "Acusacion.",
            "Jornada.",
            "Partida.",
            "registrar_sello(",
            "desbloquear",
        ):
            self.assertNotIn(llamada, self.cinematica)

    def test_sin_cinta_el_flujo_actual_se_conserva(self):
        self.assertIn('resultado.get("cinta_onirica", {})', self.capa)
        self.assertIn("super._al_firmar(resultado, formulario)", self.capa)

    def test_la_firma_se_guarda_antes_de_proyectar(self):
        guardar = self.capa.index("if not _guardar_o_avisar():")
        proyectar = self.capa.index("_reproducir_proyeccion(resultado, estado)", guardar)
        self.assertLess(guardar, proyectar)

    def test_skip_y_final_continuan_al_mismo_sello(self):
        self.assertIn("reproductor.terminada.connect(_al_terminar_proyeccion", self.capa)
        self.assertIn("_reproducir_sello(resultado)", self.capa)

    def test_el_visor_activa_la_costura(self):
        # El visor puede añadir capas posteriores siempre que mantengan la
        # proyección en su cadena de herencia. Combinaciones y anotaciones son
        # extensiones válidas; fijar una capa directa convertiría cada vertical
        # nuevo del visor en un falso negativo de CI.
        self.assertIn('path="res://guion/visor_anotaciones_app.gd"', self.escena)
        self.assertIn(
            'extends "res://guion/visor_combinaciones_app.gd"', self.capa_anotaciones
        )
        self.assertIn('extends "res://guion/visor_proyeccion_app.gd"', self.capa_combinaciones)


if __name__ == "__main__":
    unittest.main()
