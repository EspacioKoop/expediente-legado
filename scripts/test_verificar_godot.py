"""Regresiones de CI: una suite rota nunca puede pasar por cero fallos."""

import unittest

from verificar_godot import validar, version_admitida


class ValidacionGodotTest(unittest.TestCase):
    def test_suite_completa_y_creciente(self):
        for total in (376, 400):
            validar(f"{total} pasadas, 0 fallos\n", 0, 376)

    def test_rechaza_falsos_verdes(self):
        for salida in (
            "375 pasadas, 0 fallos\n",
            "376 pasadas, 1 fallos\n",
            "SCRIPT ERROR: Invalid operands\n376 pasadas, 0 fallos\n",
            "ERROR: Failed loading resource\n376 pasadas, 0 fallos\n",
            "Godot arrancó pero no ejecutó la suite\n",
            "376 pasadas, 0 fallos\n376 pasadas, 0 fallos\n",
        ):
            with self.subTest(salida=salida), self.assertRaises(ValueError):
                validar(salida, 0, 376)

    def test_rechaza_codigo_de_salida(self):
        with self.assertRaises(ValueError):
            validar("376 pasadas, 0 fallos\n", 1, 376)

    def test_importacion_no_oculta_errores_de_guion(self):
        validar("ERROR: Traducción pendiente de importar\n", 0, importando=True)
        with self.assertRaises(ValueError):
            validar("SCRIPT ERROR: Parse Error: guion roto\n", 0, importando=True)

    def test_arranque_no_admite_recursos_rotos(self):
        validar("Godot Engine\n", 0)
        with self.assertRaises(ValueError):
            validar("ERROR: Failed loading resource\n", 0)

    def test_json_corrupto_solo_se_espera_en_la_suite(self):
        error = "ERROR: Parse JSON failed. Error at line 0: Expected key\n"
        validar(error + "376 pasadas, 0 fallos\n", 0, 376)
        with self.assertRaises(ValueError):
            validar(error, 0)

    def test_el_guardado_que_falla_solo_se_espera_en_la_suite(self):
        """Las pruebas de #191 provocan estos dos; el juego no debe imprimirlos."""
        for error in (
            "ERROR: No se pudo escribir user://x.json.nuevo\n",
            "ERROR: No se pudo reemplazar user://x.json (error 1)\n",
        ):
            validar(error + "376 pasadas, 0 fallos\n", 0, 376)
            with self.assertRaises(ValueError):
                validar(error, 0)

    def test_un_error_nuevo_no_se_cuela_entre_los_provocados(self):
        """La lista es de diagnósticos concretos, no un salvoconducto."""
        salida = (
            "ERROR: Parse JSON failed. Error at line 0: Expected key\n"
            "ERROR: No se pudo cargar el recurso res://escenas/dia.tscn\n"
            "376 pasadas, 0 fallos\n"
        )
        with self.assertRaises(ValueError):
            validar(salida, 0, 376)


if __name__ == "__main__":
    unittest.main()


class VersionMotorTest(unittest.TestCase):
    """La línea declarada, no la versión exacta: un parche nuevo sirve igual."""

    def test_admite_la_version_declarada(self):
        self.assertTrue(
            version_admitida("4.7-stable", "4.7.stable.official.abc1234")
        )

    def test_admite_un_parche_de_la_misma_linea(self):
        self.assertTrue(
            version_admitida("4.7-stable", "4.7.2.stable.official.ed1daf0bf")
        )

    def test_rechaza_otra_linea(self):
        # Es el caso que hace ruido: assets y API de otra línea.
        for otra in ("4.2.2.stable.official.15073afe3", "4.8.stable.official.abc"):
            self.assertFalse(version_admitida("4.7-stable", otra))

    def test_rechaza_otro_canal(self):
        self.assertFalse(version_admitida("4.7-stable", "4.7.rc1.official.abc"))

    def test_rechaza_un_fichero_mal_escrito(self):
        with self.assertRaises(ValueError):
            version_admitida("4.7", "4.7.stable.official.abc")
