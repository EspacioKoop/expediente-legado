from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENTRADA = ROOT / "godot" / "guion" / "entrada_cinematica.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"


class EntradaCinematica3DTest(unittest.TestCase):
    def setUp(self) -> None:
        self.entrada = ENTRADA.read_text(encoding="utf-8")
        self.reproductor = REPRODUCTOR.read_text(encoding="utf-8")
        self.dia = DIA.read_text(encoding="utf-8")

    def test_entrada_deja_de_ser_cuatro_inserts_2d(self) -> None:
        self.assertEqual(self.entrada.count('"tipo": "3d"'), 4)
        self.assertNotIn('"tipo": "2d"', self.entrada)
        self.assertNotIn('"figura":', self.entrada)
        self.assertEqual(self.entrada.count('"camara": Vector3'), 4)
        self.assertEqual(self.entrada.count('"mira": Vector3'), 4)

    def test_planos_reutilizan_lugares_del_mundo_jugable(self) -> None:
        for nombre in ('"umbral"', '"terminal"', '"auditor"', '"archivo"'):
            self.assertIn(f'"nombre": {nombre}', self.entrada)
        self.assertIn("EspaciosCatalogo.OFICINA", self.entrada)
        self.assertNotIn("MeshInstance3D", self.entrada)
        self.assertNotIn("BoxMesh", self.entrada)

    def test_reproductor_usa_world3d_efectivo_sin_acoplarse_a_dia(self) -> None:
        self.assertIn("func _tiene_mundo_3d() -> bool:", self.reproductor)
        self.assertIn("get_world_3d() != null", self.reproductor)
        self.assertIn("mundo != null or", self.reproductor)
        self.assertIn("not es_2d and _tiene_mundo_3d()", self.reproductor)
        self.assertNotIn('get("_mundo")', self.reproductor)
        self.assertNotIn("get_parent()._mundo", self.reproductor)

    def test_skip_y_fin_normal_comparten_salida_y_contador(self) -> None:
        salto = self.reproductor.split("func saltar() -> void:", 1)[1].split(
            "func _process", 1
        )[0]
        self.assertIn("_terminar()", salto)
        self.assertIn("Cinematica.anotar_vista(_estado, _id)", self.reproductor)
        self.assertIn("terminada.emit()", self.reproductor)
        self.assertIn("_entrada.terminada.connect(_cerrar_vuelta)", self.dia)

    def test_se_conservan_identidad_repeticion_y_remate(self) -> None:
        for contrato in (
            'const ID := "entrada"',
            'const USUARIO := "auditor01"',
            "Cinematica.resolver(planos(vistas), {\"usuario\": USUARIO}, vistas)",
            '"rotulo": "ENTRADA_RESTAURANDO"',
            '"rotulo": "ENTRADA_AUDITOR"',
            '"rotulo": "ENTRADA_NADIE_MIRA"',
            "REGISTRO_POR_VUELTA",
        ):
            self.assertIn(contrato, self.entrada)


if __name__ == "__main__":
    unittest.main()
