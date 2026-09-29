import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

import check_reservas_capacity as capacidad


class CapacidadRegistroTest(unittest.TestCase):
    def test_umbrales_no_bloquean_y_cambian_en_el_punto_exacto(self):
        self.assertTrue(capacidad.mensaje(1713, 1999).startswith("OK:"))
        self.assertTrue(capacidad.mensaje(1713, 2000).startswith("ROTAR:"))
        self.assertTrue(capacidad.mensaje(1713, 2299).startswith("ROTAR:"))
        self.assertTrue(capacidad.mensaje(1713, 2300).startswith("URGENTE:"))
        self.assertTrue(capacidad.mensaje(1713, 2500).startswith("URGENTE:"))

    def test_consulta_solo_el_registro_activo_de_la_configuracion(self):
        with (
            patch.object(capacidad.rollover, "cargar_config", return_value=(1900, [182, 1713, 1900])),
            patch.object(capacidad.rollover.base, "REPO", "EspacioKoop/expediente-legado"),
            patch.object(
                capacidad.rollover.base,
                "api_json",
                return_value=({"comments": 2000}, {}),
            ) as api,
        ):
            self.assertEqual(capacidad.comprobar(), (1900, 2000))
        api.assert_called_once_with("GET", "/repos/EspacioKoop/expediente-legado/issues/1900")

    def test_contador_invalido_falla_cerrado_sin_tratarse_como_cero(self):
        for valor in (None, "2000", True, -1):
            with self.subTest(valor=valor):
                with (
                    patch.object(capacidad.rollover, "cargar_config", return_value=(1713, [1713])),
                    patch.object(capacidad.rollover.base, "REPO", "EspacioKoop/expediente-legado"),
                    patch.object(capacidad.rollover.base, "api_json", return_value=({"comments": valor}, {})),
                ):
                    with self.assertRaises(ValueError):
                        capacidad.comprobar()

    def test_avisa_y_resume_sin_escribir_en_github(self):
        with tempfile.TemporaryDirectory() as temporal:
            resumen = Path(temporal) / "summary.md"
            salida = io.StringIO()
            with (
                patch.object(capacidad, "comprobar", return_value=(1713, 2300)),
                patch.dict("os.environ", {"GITHUB_STEP_SUMMARY": str(resumen)}),
                redirect_stdout(salida),
            ):
                self.assertEqual(capacidad.main(), 0)
            self.assertIn("::warning::Registro de reservas #1713", salida.getvalue())
            self.assertIn("2300/2500", resumen.read_text(encoding="utf-8"))

    def test_error_de_api_avisa_pero_no_rompe_el_barrido(self):
        salida = io.StringIO()
        with patch.object(capacidad, "comprobar", side_effect=RuntimeError("API 503")), redirect_stdout(salida):
            self.assertEqual(capacidad.main(), 0)
        self.assertIn("::warning::No se pudo comprobar", salida.getvalue())

    def test_error_del_resumen_no_rompe_el_barrido(self):
        salida = io.StringIO()
        with tempfile.TemporaryDirectory() as temporal:
            with (
                patch.object(capacidad, "comprobar", return_value=(1713, 100)),
                patch.dict("os.environ", {"GITHUB_STEP_SUMMARY": temporal}),
                redirect_stdout(salida),
            ):
                self.assertEqual(capacidad.main(), 0)
        self.assertIn("::warning::No se pudo escribir", salida.getvalue())


if __name__ == "__main__":
    unittest.main()
