from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot/guion/dia_climax_os98_app.gd"
ARCHIVADO = ROOT / "godot/guion/dia_archivado_app.gd"
PRUEBA = ROOT / "godot/pruebas/pruebas_texto_corrupto_rotulo_3d_806.gd"


class TextoCorruptoRotulo3D806Test(unittest.TestCase):
    def test_superficie_es_el_rotulo_jugable_del_archivado(self):
        archivado = ARCHIVADO.read_text(encoding="utf-8")
        self.assertIn('rotulo.name = "DestinoArchivado"', archivado)
        self.assertIn("archivador.add_child(rotulo)", archivado)
        controlador = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('find_children("DestinoArchivado", "Label3D"', controlador)

    def test_reutiliza_motor_y_contexto_sin_tocar_progreso(self):
        fuente = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('contexto.get("efecto_texto"', fuente)
        self.assertIn("TextoCorruptoNarrativo.aplicar", fuente)
        self.assertIn("_sincronizar_rotulos_3d", fuente)
        for prohibido in ("ArchivadoBandeja.colocar", "jornada[", "Partida.", "registrar_"):
            self.assertNotIn(prohibido, fuente)

    def test_accesibilidad_y_restauracion(self):
        fuente = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn("reduccion_movimiento", fuente)
        self.assertIn('get_meta("texto_corrupto_critico"', fuente)
        self.assertIn("_restaurar_rotulo_3d", fuente)
        prueba = PRUEBA.read_text(encoding="utf-8")
        self.assertIn("fase normal restaura destino", prueba)
        self.assertIn("rótulo crítico conserva legibilidad", prueba)


if __name__ == "__main__":
    unittest.main()
