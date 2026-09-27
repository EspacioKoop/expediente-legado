import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
DIA_ESCRITORIO = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
AVATAR = ROOT / "godot" / "guion" / "gato_asistente_2d.gd"
PASEO = ROOT / "godot" / "guion" / "gato_asistente_paseo_os98.gd"


class GatoAsistenteEscritorioTest(unittest.TestCase):
    def test_prometeo_se_promueve_al_shell_os98(self):
        gato = DIA_GATO.read_text(encoding="utf-8")
        escritorio = DIA_ESCRITORIO.read_text(encoding="utf-8")

        self.assertIn("func integrar_asistente_os98(escritorio: Control) -> void:", gato)
        self.assertIn("avatar.reparent(escritorio, false)", gato)
        self.assertIn("GatoAsistentePaseoOs98.new()", gato)
        self.assertIn('dia.call("integrar_asistente_os98", escritorio)', escritorio)

    def test_bocadillo_permanece_en_siga_pero_el_arrastre_es_del_avatar(self):
        fuente = DIA_GATO.read_text(encoding="utf-8")

        self.assertIn("visor.add_child(conjunto)", fuente)
        self.assertIn("conjunto.mouse_filter = Control.MOUSE_FILTER_IGNORE", fuente)
        self.assertIn("avatar.gui_input.connect(_al_input_asistente_siga.bind(avatar))", fuente)
        self.assertIn("call_deferred(\"_colocar_asistente_siga\", conjunto, visor)", fuente)

    def test_avatar_reutiliza_las_ocho_poses_del_atlas(self):
        fuente = AVATAR.read_text(encoding="utf-8")

        for constante in (
            "FRAME_SATISFECHO := 4",
            "FRAME_LOAF := 5",
            "FRAME_MIRANDO := 6",
            "FRAME_ESPALDA := 7",
        ):
            self.assertIn(constante, fuente)
        self.assertIn("CICLO_ANIMACION := 14.0", fuente)
        self.assertIn("frame = FRAME_LOAF", fuente)
        self.assertIn("frame = FRAME_ESPALDA", fuente)

    def test_paseo_es_determinista_y_respeta_reduccion_movimiento(self):
        fuente = PASEO.read_text(encoding="utf-8")

        self.assertIn("DESTINOS_NORMALIZADOS", fuente)
        self.assertIn("set_process(not reduccion_movimiento)", fuente)
        self.assertIn('get_node_or_null("BarraInferior")', fuente)
        self.assertNotIn("RandomNumberGenerator", fuente)
        self.assertNotIn("randf", fuente)
        self.assertNotIn("randi", fuente)

    def test_adopcion_os98_conserva_el_gato_fuera_de_siga(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_gato_asistente_escritorio.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("19 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
