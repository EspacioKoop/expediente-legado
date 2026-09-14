from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"


class CinematicaReduccionMovimientoTest(unittest.TestCase):
    def test_preferencia_existe_y_se_lee_al_iniciar_cada_cinematica(self) -> None:
        preferencias = PREFERENCIAS.read_text(encoding="utf-8")
        reproductor = REPRODUCTOR.read_text(encoding="utf-8")
        self.assertIn('"reduccion_movimiento": false', preferencias)
        self.assertIn("PreferenciasSiga.cargar()", reproductor)
        self.assertIn('get("reduccion_movimiento", false)', reproductor)

    def test_planos_3d_quedan_estaticos_sin_eliminar_la_escena(self) -> None:
        codigo = REPRODUCTOR.read_text(encoding="utf-8")
        self.assertIn(
            "var factor_movimiento := 0.0 if _reduccion_movimiento else avance",
            codigo,
        )
        self.assertIn("destino.normalized() * -0.25 * factor_movimiento", codigo)
        self.assertIn("_camara.global_position = destino + acercamiento", codigo)
        self.assertIn("_camara.look_at", codigo)

    def test_planos_2d_aparecen_en_pose_final_sin_animacion(self) -> None:
        codigo = REPRODUCTOR.read_text(encoding="utf-8")
        self.assertIn(
            "var factor_movimiento := 1.0 if _reduccion_movimiento else avance",
            codigo,
        )
        self.assertIn("desde.lerp(hasta, factor_movimiento)", codigo)
        self.assertIn("_figuras.draw_rect", codigo)

    def test_reduccion_no_cambia_duracion_skip_ni_final(self) -> None:
        codigo = REPRODUCTOR.read_text(encoding="utf-8")
        self.assertIn('var duracion: float = plano["segundos"]', codigo)
        self.assertIn('evento.is_action_pressed("ui_accept")', codigo)
        self.assertIn('evento.is_action_pressed("ui_cancel")', codigo)
        self.assertIn("terminada.emit()", codigo)
        self.assertIn("Cinematica.anotar_vista", codigo)
        self.assertNotIn("if _reduccion_movimiento:\n\t\t_terminar()", codigo)


if __name__ == "__main__":
    unittest.main()
