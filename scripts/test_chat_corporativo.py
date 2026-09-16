import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "chat_corporativo.json"
MODELO = ROOT / "godot" / "guion" / "chat_corporativo_modelo.gd"
PRUEBA_GODOT = ROOT / "godot" / "pruebas" / "pruebas_chat_corporativo.gd"
COMPANEROS = ROOT / "godot" / "guion" / "companeros.gd"
WEB98 = ROOT / "godot" / "datos" / "web98_indice.json"


def cargar_catalogo() -> dict:
    return json.loads(CATALOGO.read_text(encoding="utf-8"))


class ChatCorporativoTest(unittest.TestCase):
    def test_catalogo_declara_canales_nicks_y_presencia(self) -> None:
        datos = cargar_catalogo()
        canales = datos["canales"]
        usuarios = datos["usuarios"]
        companeros = [usuario for usuario in usuarios if usuario["tipo"] == "companero"]

        self.assertEqual(datos["version"], 1)
        self.assertGreaterEqual(len(canales), 3)
        self.assertGreaterEqual(len(companeros), 4)
        self.assertGreaterEqual(datos["historial_max"], 1)

        ids_canales = [canal["id"] for canal in canales]
        self.assertEqual(len(ids_canales), len(set(ids_canales)))
        for canal in canales:
            self.assertTrue(canal["nombre"].startswith("#"))
            self.assertTrue(canal["descripcion"])
            self.assertGreaterEqual(canal["historial_max"], 1)
            self.assertIsInstance(canal["requiere_conocimiento"], list)
            self.assertIsInstance(canal["requiere_eventos"], list)

        ids_usuarios = [usuario["id"] for usuario in usuarios]
        nicks = [usuario["nick"] for usuario in usuarios]
        self.assertEqual(len(ids_usuarios), len(set(ids_usuarios)))
        self.assertEqual(len(nicks), len(set(nicks)))

        fuente_companeros = COMPANEROS.read_text(encoding="utf-8")
        ids_reales = set(re.findall(r'"id": "([a-z0-9_]+)"', fuente_companeros))
        ids_chat = {usuario["companero_id"] for usuario in companeros}
        self.assertLessEqual(ids_chat, ids_reales)

        estados_validos = {"conectado", "ausente", "desconectado"}
        for usuario in companeros:
            self.assertTrue(usuario["estilo"])
            self.assertGreaterEqual(len(usuario["canales"]), 1)
            self.assertGreaterEqual(len(usuario["presencia"]), 1)
            for regla in usuario["presencia"]:
                self.assertIn(regla["estado"], estados_validos)
                self.assertRegex(regla["desde"], r"^\d{2}:\d{2}$")
                self.assertRegex(regla["hasta"], r"^\d{2}:\d{2}$")

    def test_mensajes_referencian_autores_canales_y_enlaces_reales(self) -> None:
        datos = cargar_catalogo()
        mensajes = datos["mensajes"]
        canales = {canal["id"] for canal in datos["canales"]}
        usuarios = {usuario["id"] for usuario in datos["usuarios"]}
        web_ids = {recurso["id"] for recurso in json.loads(WEB98.read_text(encoding="utf-8"))["recursos"]}

        ids = [mensaje["id"] for mensaje in mensajes]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertGreaterEqual(len(mensajes), 12)
        self.assertTrue(any(mensaje["tipo"] == "sistema" for mensaje in mensajes))
        self.assertTrue(any(mensaje["tipo"] == "presencia" for mensaje in mensajes))
        self.assertTrue(any(2 <= len(mensaje.get("opciones", [])) <= 4 for mensaje in mensajes))

        for mensaje in mensajes:
            self.assertIn(mensaje["canal"], canales)
            self.assertIn(mensaje["autor"], usuarios)
            self.assertTrue(mensaje["texto"])
            self.assertRegex(mensaje["hora"], r"^\d{2}:\d{2}$")
            self.assertIsInstance(mensaje["requiere_conocimiento"], list)
            self.assertIsInstance(mensaje["requiere_eventos"], list)
            opciones = mensaje.get("opciones", [])
            if opciones:
                self.assertGreaterEqual(len(opciones), 2)
                self.assertLessEqual(len(opciones), 4)
                for opcion in opciones:
                    self.assertTrue(opcion["id"])
                    self.assertTrue(opcion["texto"])
                    self.assertTrue(opcion["contestacion"])
            enlace = mensaje.get("enlace")
            if enlace:
                self.assertEqual(enlace["tipo"], "web98")
                self.assertIn(enlace["recurso_id"], web_ids)
                self.assertIsInstance(enlace["requiere_conocimiento"], list)
                self.assertIsInstance(enlace["requiere_eventos"], list)

    def test_incidencia_y_enlace13_estan_gobernados_por_estado(self) -> None:
        datos = cargar_catalogo()
        canales = {canal["id"]: canal for canal in datos["canales"]}
        mensajes = datos["mensajes"]

        self.assertEqual(canales["inc-impresora"]["requiere_eventos"], ["impresora_atascada"])
        incidencia = [mensaje for mensaje in mensajes if mensaje["canal"] == "inc-impresora"]
        self.assertGreaterEqual(len(incidencia), 2)
        for mensaje in incidencia:
            self.assertIn("impresora_atascada", mensaje["requiere_eventos"])

        restringidos = [
            mensaje
            for mensaje in mensajes
            if "enlace13" in mensaje.get("requiere_conocimiento", [])
        ]
        self.assertGreaterEqual(len(restringidos), 2)
        for mensaje in restringidos:
            self.assertNotIn("enlace13", mensaje["texto"].lower())
            enlace = mensaje.get("enlace")
            if enlace:
                self.assertEqual(enlace["recurso_id"], "diagnostico-enlace13")
                self.assertIn("enlace13", enlace["requiere_conocimiento"])

    def test_modelo_es_offline_y_usa_solo_tiempo_narrativo(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn("class_name ChatCorporativoModelo", fuente)
        self.assertIn("func canales_visibles", fuente)
        self.assertIn("func estado_usuario", fuente)
        self.assertIn("func hora_narrativa", fuente)
        self.assertIn("func mensajes_de_canal", fuente)
        self.assertIn("func opciones_respuesta", fuente)
        self.assertIn("func enlace_de_mensaje", fuente)
        self.assertIn("Jornada.ACCIONES_POR_DIA", fuente)
        self.assertIn("FileAccess.get_file_as_string(ruta)", fuente)
        for prohibido in (
            "HTTPRequest",
            "HTTPClient",
            "TCPServer",
            "StreamPeerTCP",
            "WebSocketPeer",
            "Time.get_",
            "Time.get_datetime",
            "OS.execute(",
            "OS.create_process(",
        ):
            self.assertNotIn(prohibido, fuente)

    def test_no_declara_entrada_libre(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        datos = CATALOGO.read_text(encoding="utf-8")
        for prohibido in ("texto_libre", "entrada_libre", "enviar_texto", "servidor_irc"):
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
