import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "bbs98.json"
MODELO = ROOT / "godot" / "guion" / "bbs98_modelo.gd"
PRUEBA_GODOT = ROOT / "godot" / "pruebas" / "pruebas_bbs98.gd"
COMPANEROS = ROOT / "godot" / "guion" / "companeros.gd"


def cargar_catalogo() -> dict:
    return json.loads(CATALOGO.read_text(encoding="utf-8"))


class Bbs98Test(unittest.TestCase):
    def test_catalogo_declara_tres_tablones_con_identidad_distinta(self) -> None:
        datos = cargar_catalogo()
        tablones = datos["tablones"]

        self.assertEqual(datos["version"], 1)
        self.assertGreaterEqual(len(tablones), 3)
        self.assertGreaterEqual(len({tablon["categoria"] for tablon in tablones}), 3)
        self.assertEqual(len({tablon["id"] for tablon in tablones}), len(tablones))
        self.assertEqual(len({tablon["url"] for tablon in tablones}), len(tablones))
        self.assertTrue(any(tablon["estado"] == "abierto" for tablon in tablones))
        self.assertTrue(any(tablon["estado"] == "cerrado" for tablon in tablones))
        self.assertTrue(any(tablon["estado"] == "archivado" for tablon in tablones))

        for tablon in tablones:
            self.assertTrue(tablon["nombre"])
            self.assertTrue(tablon["descripcion"])
            self.assertTrue(tablon["url"].startswith("http://"))
            self.assertGreaterEqual(len(tablon["terminos_indexados"]), 3)
            self.assertIsInstance(tablon["requiere_conocimiento"], list)

    def test_hilos_y_mensajes_referencian_entidades_estables(self) -> None:
        datos = cargar_catalogo()
        tablones = {tablon["id"] for tablon in datos["tablones"]}
        usuarios = {usuario["id"] for usuario in datos["usuarios"]}
        hilos = {hilo["id"]: hilo for hilo in datos["hilos"]}
        mensajes = {mensaje["id"]: mensaje for mensaje in datos["mensajes"]}

        self.assertGreaterEqual(len(hilos), 6)
        self.assertGreaterEqual(len(mensajes), 12)
        self.assertTrue(any(hilo["estado"] == "cerrado" for hilo in hilos.values()))
        self.assertTrue(any(hilo["estado"] == "archivado" for hilo in hilos.values()))

        tipos = {mensaje["tipo"] for mensaje in mensajes.values()}
        estados = {mensaje["estado"] for mensaje in mensajes.values()}
        self.assertIn("normal", tipos)
        self.assertIn("moderacion", tipos)
        self.assertIn("sistema", tipos)
        self.assertIn("eliminado", estados)
        self.assertIn("movido", estados)

        for hilo in hilos.values():
            self.assertIn(hilo["tablon_id"], tablones)
            self.assertIsInstance(hilo["requiere_conocimiento"], list)
            self.assertIsInstance(hilo["requiere_companeros"], list)
        for mensaje in mensajes.values():
            self.assertIn(mensaje["hilo_id"], hilos)
            self.assertIn(mensaje["autor_id"], usuarios)
            self.assertIsInstance(mensaje["requiere_conocimiento"], list)
            self.assertIsInstance(mensaje["requiere_companeros"], list)
            citado = mensaje["cita_mensaje_id"]
            if citado:
                self.assertIn(citado, mensajes)
            movido = mensaje["movido_a_hilo_id"]
            if movido:
                self.assertIn(movido, hilos)

    def test_usuarios_recurren_y_hay_huella_opcional_de_companero(self) -> None:
        datos = cargar_catalogo()
        mensajes = datos["mensajes"]
        conteo: dict[str, set[str]] = {}
        hilo_a_tablon = {hilo["id"]: hilo["tablon_id"] for hilo in datos["hilos"]}
        for mensaje in mensajes:
            conteo.setdefault(mensaje["autor_id"], set()).add(
                hilo_a_tablon[mensaje["hilo_id"]]
            )
        self.assertTrue(any(len(tablones) >= 2 for tablones in conteo.values()))

        fuente_companeros = COMPANEROS.read_text(encoding="utf-8")
        ids_reales = set(re.findall(r'"id": "([a-z0-9_]+)"', fuente_companeros))
        huellas = [usuario for usuario in datos["usuarios"] if usuario["companero_id"]]
        self.assertGreaterEqual(len(huellas), 1)
        for usuario in huellas:
            self.assertIn(usuario["companero_id"], ids_reales)
            self.assertTrue(usuario["firma"])
            self.assertTrue(usuario["estilo"])

    def test_modelo_es_offline_y_no_declara_publicacion_libre(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        datos = CATALOGO.read_text(encoding="utf-8")
        self.assertIn("class_name Bbs98Modelo", fuente)
        self.assertIn("func tablones_visibles", fuente)
        self.assertIn("func hilos_de", fuente)
        self.assertIn("func mensajes_de", fuente)
        self.assertIn("func buscar", fuente)
        self.assertIn("func referencia_de_mensaje", fuente)
        self.assertIn("func recursos_web", fuente)
        self.assertIn("FileAccess.get_file_as_string(ruta)", fuente)
        for prohibido in (
            "HTTPRequest",
            "HTTPClient",
            "TCPServer",
            "StreamPeerTCP",
            "WebSocketPeer",
            "OS.execute(",
            "OS.create_process(",
            "texto_libre",
            "entrada_libre",
            "publicar(",
            "enviar(",
        ):
            self.assertNotIn(prohibido, fuente)
            self.assertNotIn(prohibido, datos)

    def test_contrato_ejecutable_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                str(PRUEBA_GODOT.relative_to(ROOT / "godot")),
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
