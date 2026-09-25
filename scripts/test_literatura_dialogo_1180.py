from pathlib import Path
import json
import os
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRODUCTOR = ROOT / "godot" / "guion" / "literatura_dialogo.gd"
REENTRADA = ROOT / "godot" / "guion" / "literatura_dialogo_reentrada.gd"
MOVIMIENTO = ROOT / "godot" / "guion" / "literatura_movimiento_contexto.gd"
CATALOGO = ROOT / "godot" / "datos" / "literatura_dialogos.json"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
DIEGETICO = ROOT / "godot" / "guion" / "dialogo_diegetico.gd"
GESTOR = ROOT / "godot" / "literatura" / "gestor_literatura.gd"
TEST_GODOT = "res://pruebas/pruebas_literatura_dialogo_1180.gd"


class LiteraturaDialogo1180Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.productor = PRODUCTOR.read_text(encoding="utf-8")
        cls.reentrada = REENTRADA.read_text(encoding="utf-8")
        cls.movimiento = MOVIMIENTO.read_text(encoding="utf-8")
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.diegetico = DIEGETICO.read_text(encoding="utf-8")
        cls.gestor = GESTOR.read_text(encoding="utf-8")

    def test_catalogo_tiene_dos_ramas_y_movimiento_contextual(self) -> None:
        dialogos = self.catalogo["dialogos"]
        self.assertEqual(len(dialogos), 1)
        dialogo = dialogos[0]
        self.assertEqual(len(dialogo["ramas"]), 2)
        self.assertEqual(dialogo["movimiento"]["id"], "barroco")
        self.assertEqual(dialogo["npc"]["id"], "mediadora_archivo_98")
        self.assertTrue(all(rama["consecuencia_visible"] for rama in dialogo["ramas"]))
        self.assertEqual(
            {rama["insight_id"] for rama in dialogo["ramas"]},
            {"apariencia_y_eleccion"},
        )

    def test_productor_solo_escribe_contrato_literario(self) -> None:
        self.assertIn("LiteraturaEventos.CANAL_INSIGHT", self.productor)
        self.assertIn('"productor": "dialogo_literario"', self.productor)
        self.assertIn('"dialogo_id"', self.productor)
        self.assertIn('"rama_id"', self.productor)
        self.assertIn('"movimiento_id"', self.productor)
        for forbidden in (
            "Partida",
            "GestorMomentum",
            "GestorArquetipos",
            "Prometeo",
            "alignment",
            "reputacion",
        ):
            self.assertNotIn(forbidden, self.productor)

    def test_hay_dos_consumidores_independientes(self) -> None:
        self.assertIn('"consumidor": "dialogo_reentrada"', self.reentrada)
        self.assertIn('"consumidor": "contexto_movimiento"', self.movimiento)
        self.assertIn("insight_de_dialogo", self.reentrada)
        self.assertIn("insight_de_dialogo", self.movimiento)

    def test_dialogo_se_monta_en_el_recorrido_real(self) -> None:
        self.assertIn('"dialogo_literario": DIALOGO_LITERARIO_1180', self.dia)
        self.assertIn('"fuente_dialogo_literario": FUENTE_LITERARIA_1180', self.dia)
        self.assertIn("DialogoDiegetico", self.dia)
        self.assertIn("mostrar_eleccion(", self.dia)
        self.assertIn('"resolver_dialogo"', self.dia)
        self.assertIn('"resolver_reentrada_dialogo"', self.dia)
        self.assertIn("func mostrar_eleccion(", self.diegetico)
        self.assertIn("func resolver_dialogo(", self.gestor)
        self.assertIn("func resolver_reentrada_dialogo(", self.gestor)

    def test_godot_dialogo_contract(self) -> None:
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="literatura-dialogo-1180-") as tmp:
            env = os.environ.copy()
            env["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                env[key] = str(Path(tmp) / key)
            result = subprocess.run(
                [
                    engine,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    TEST_GODOT,
                ],
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=240,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("0 fallos", result.stdout)


if __name__ == "__main__":
    unittest.main()
