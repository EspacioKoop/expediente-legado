import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")
RELACION = ROOT / "godot" / "guion" / "dia_relacion_onirica_app.gd"
ECOS = ROOT / "godot" / "guion" / "dia_ecos_archivo_app.gd"
RELACION_3D = ROOT / "godot" / "guion" / "sueno_relacion_onirica_3d.gd"
ECOS_3D = ROOT / "godot" / "guion" / "sueno_ecos_archivo_3d.gd"
SESION = ROOT / "godot" / "guion" / "sueno_puzzle_sesion.gd"


class SuenoPuzzlePersistenciaTest(unittest.TestCase):
    def test_contrato_de_sesion_en_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_sueno_puzzle_sesion.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_ambos_controllers_restauran_antes_de_sortear(self):
        relacion = "".join(RELACION.read_text(encoding="utf-8").split())
        ecos = "".join(ECOS.read_text(encoding="utf-8").split())
        for codigo, tipo in (
            (relacion, "TIPO_RELACION"),
            (ecos, "TIPO_ECOS"),
        ):
            self.assertIn("SuenoPuzzleSesion.registrada_esta_noche(dia.jornada)", codigo)
            self.assertIn("SuenoPuzzleSesion.actual(dia.jornada)", codigo)
            self.assertIn(f"SuenoPuzzleSesion.{tipo}", codigo)
            self.assertIn('sesion.get("datos",{})', codigo)
            self.assertIn("_candidato_guardado(dia,sesion)", codigo)

    def test_cambio_de_tipo_no_puede_rerollear_otro_puzzle(self):
        relacion = RELACION.read_text(encoding="utf-8")
        ecos = ECOS.read_text(encoding="utf-8")
        self.assertIn(
            'String(sesion.get("tipo", "")) != SuenoPuzzleSesion.TIPO_RELACION',
            relacion,
        )
        self.assertIn(
            'String(sesion.get("tipo", "")) != SuenoPuzzleSesion.TIPO_ECOS',
            ecos,
        )

    def test_cada_interaccion_dispara_guardado_canonico(self):
        for ruta in (RELACION_3D, ECOS_3D):
            codigo = ruta.read_text(encoding="utf-8")
            self.assertIn("signal estado_cambiado(estado: String)", codigo)
            self.assertIn("estado_cambiado.emit(", codigo)
        for ruta in (RELACION, ECOS):
            codigo = ruta.read_text(encoding="utf-8")
            self.assertIn("estado_cambiado.connect(", codigo)
            self.assertIn('dia.call("_guardar_o_avisar", "")', codigo)

    def test_sesion_vive_en_jornada_y_no_en_archivo_paralelo(self):
        codigo = SESION.read_text(encoding="utf-8")
        self.assertIn('CLAVE := "puzzle_onirico_actual"', codigo)
        self.assertIn("jornada[CLAVE]", codigo)
        self.assertNotIn("FileAccess", codigo)
        self.assertNotIn("user://", codigo)
        self.assertIn("registrada_esta_noche", codigo)
        self.assertIn("_misma_identidad", codigo)
        self.assertIn("terminal(sesion", codigo)

    def test_runner_cubre_guardado_real_de_partida(self):
        prueba = (ROOT / "godot" / "pruebas" / "pruebas_sueno_puzzle_sesion.gd").read_text(
            encoding="utf-8"
        )
        self.assertIn("PartidaModelo.new()", prueba)
        self.assertIn("partida.guardar(ruta)", prueba)
        self.assertIn("recargada.cargar(ruta)", prueba)
        self.assertIn('get("intentos", -1)', prueba)


if __name__ == "__main__":
    unittest.main()
