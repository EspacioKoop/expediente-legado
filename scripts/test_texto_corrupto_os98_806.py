from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot/guion/dia_climax_os98_app.gd"
PRUEBA = ROOT / "godot/pruebas/pruebas_texto_corrupto_os98_806.gd"


class TextoCorruptoOs98806Test(unittest.TestCase):
    def test_controller_reutiliza_contexto_y_visor_real(self):
        fuente = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('find_child("VisorDocumento"', fuente)
        self.assertIn('contexto.get("efecto_texto"', fuente)
        self.assertIn("TextoCorruptoNarrativo.aplicar", fuente)
        self.assertIn("PreferenciasSiga.cargar()", fuente)

    def test_no_toca_navegador_explorador_ni_estado_de_progreso(self):
        fuente = CONTROLADOR.read_text(encoding="utf-8")
        for prohibido in (
            "registrar_documento(",
            "registrar_ruta(",
            "Prometeo.",
            "partida.estado[",
        ):
            self.assertNotIn(prohibido, fuente)

    def test_restauracion_y_accesibilidad_estan_cubiertas(self):
        fuente = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn("_restaurar_documento", fuente)
        self.assertIn("reduccion_movimiento", fuente)
        self.assertIn('get_meta("texto_corrupto_critico"', fuente)
        prueba = PRUEBA.read_text(encoding="utf-8")
        self.assertIn("fase normal restaura el segundo documento", prueba)
        self.assertIn("contenido crítico queda legible", prueba)


if __name__ == "__main__":
    unittest.main()
