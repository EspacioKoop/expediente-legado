from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import registrar_playtest_162 as playtest  # noqa: E402


BASE = {
    "fecha": "2026-09-28T20:20:00+02:00",
    "participante": "tester-02",
    "plataforma": "Linux",
    "build_sha": "def456",
    "mando_modelo": "Mando USB",
    "ui_tres_huecos": True,
    "foco_teclado_mando": True,
    "seleccion_vacia_segura": True,
    "repeticion_visible": True,
    "relacion_conocida_visible": True,
    "selecciones_distintas_visibles": True,
    "recarga_determinista": True,
    "sin_documentos_desconocidos": True,
    "salida_segura": True,
    "sin_recompensa_mecanica": True,
    "mando_fisico": True,
    "sin_incidencia_bloqueante": True,
    "contradicciones_canonicas_resueltas": False,
    "fuente_contradicciones": "",
    "incidencia": "",
    "observaciones": "",
}


class RegistrarPlaytest162Test(unittest.TestCase):
    def test_gate_visual_puede_cumplir_sin_cerrar_el_issue(self):
        gate = playtest.evaluar_gate(dict(BASE))
        self.assertTrue(gate["gate_visual_mando"])
        self.assertFalse(gate["contradicciones_canonicas_resueltas"])
        self.assertFalse(gate["issue_completamente_cerrable"])

    def test_cualquier_check_visual_bloquea_su_gate(self):
        for clave in playtest.CHECKS:
            with self.subTest(clave=clave):
                gate = playtest.evaluar_gate(dict(BASE, **{clave: False}))
                self.assertFalse(gate["gate_visual_mando"])

    def test_declarar_resuelto_sin_fuente_no_cierra(self):
        gate = playtest.evaluar_gate(
            dict(BASE, contradicciones_canonicas_resueltas=True)
        )
        self.assertFalse(gate["contradicciones_canonicas_resueltas"])
        self.assertFalse(gate["issue_completamente_cerrable"])

    def test_solo_con_fuente_canonica_y_gate_visual_queda_cerrable(self):
        gate = playtest.evaluar_gate(
            dict(
                BASE,
                contradicciones_canonicas_resueltas=True,
                fuente_contradicciones="godot/datos/contradicciones.json@abc123",
            )
        )
        self.assertTrue(gate["contradicciones_canonicas_resueltas"])
        self.assertTrue(gate["issue_completamente_cerrable"])

    def test_informe_no_infiere_contradicciones(self):
        informe = playtest.render_markdown(dict(BASE))
        self.assertIn("gate visual/mando de #162: **CUMPLE**", informe)
        self.assertIn("semántica canónica de contradicciones: **PENDIENTE**", informe)
        self.assertIn("#162 completamente cerrable: **NO**", informe)
        self.assertIn("no se deduce de texto, colores ni similitud", informe)


if __name__ == "__main__":
    unittest.main()
