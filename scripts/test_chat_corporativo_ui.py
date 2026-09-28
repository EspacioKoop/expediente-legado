import json
import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
TEXTOS = ROOT / "godot" / "datos" / "chat_corporativo_textos.json"
CLIENTE = ROOT / "godot" / "guion" / "chat_corporativo_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
LANZADOR = ROOT / "godot" / "guion" / "dia_buscar_ejecutar_app.gd"
PRUEBA_GODOT = ROOT / "godot" / "pruebas" / "pruebas_chat_corporativo_ui.gd"


class ChatCorporativoUiTest(unittest.TestCase):
    def test_cliente_reutiliza_modelo_y_no_declara_entrada_libre(self) -> None:
        fuente = CLIENTE.read_text(encoding="utf-8")
        self.assertIn("class_name ChatCorporativoSiga", fuente)
        self.assertIn("ChatCorporativoModelo.new()", fuente)
        self.assertIn("_modelo.canales_visibles()", fuente)
        self.assertIn("_modelo.presencias(_canal_actual)", fuente)
        self.assertIn("_modelo.mensajes_de_canal(_canal_actual)", fuente)
        self.assertIn("_modelo.opciones_respuesta(_mensaje_actual)", fuente)
        self.assertIn("_modelo.enlace_de_mensaje(_mensaje_actual)", fuente)
        self.assertNotIn("LineEdit.new()", fuente)
        self.assertNotIn("TextEdit.new()", fuente)
        self.assertNotIn("HTTPRequest", fuente)
        self.assertNotIn("WebSocket", fuente)

    def test_interfaz_es_nativa_accesible_y_sin_animacion_obligatoria(self) -> None:
        fuente = CLIENTE.read_text(encoding="utf-8")
        self.assertGreaterEqual(fuente.count("ItemList.new()"), 3)
        self.assertIn("Button.new()", fuente)
        self.assertIn("selection_enabled = true", fuente)
        self.assertIn("size_flags_horizontal = Control.SIZE_EXPAND_FILL", fuente)
        self.assertIn("size_flags_vertical = Control.SIZE_EXPAND_FILL", fuente)
        self.assertNotIn("Tween", fuente)
        self.assertNotIn("AnimationPlayer", fuente)

    def test_textos_visibles_estan_en_catalogo_dedicado(self) -> None:
        datos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        for clave in (
            "titulo_app",
            "canales",
            "presencia",
            "sin_canales",
            "sin_mensajes",
            "hora",
            "abrir_web98",
            "responder",
            "respuesta_elegida",
            "contestacion",
        ):
            self.assertTrue(datos[clave])

    def test_adaptador_registra_persiste_y_abre_web98_por_id(self) -> None:
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn('var _chat_app: EscritorioSigaApp', fuente)
        self.assertIn(
            '"chat-corporativo",\n\t\tChatCorporativoSiga.texto("titulo_app")',
            fuente,
        )
        self.assertIn('Callable(self, "_crear_chat_corporativo")', fuente)
        self.assertIn("_chat_app.persistir_estado = true", fuente)
        self.assertIn('obtener_estado_local("respuestas_por_partida", {})', fuente)
        self.assertIn(
            '_chat_app.establecer_estado_local("respuestas_por_partida", por_partida)',
            fuente,
        )
        self.assertIn("ChatCorporativoSiga.new()", fuente)
        self.assertIn("chat.respuesta_elegida.connect(_registrar_respuesta_chat)", fuente)
        self.assertIn("chat.enlace_abierto.connect(_abrir_enlace_chat)", fuente)
        self.assertIn("Web98Indice.new()", fuente)
        self.assertIn("indice.recursos_visibles()", fuente)
        self.assertIn("_navegador_app.abrir", fuente)
        self.assertIn("_navegador_vista.navegar(url)", fuente)

    def test_contexto_del_chat_deriva_de_jornada_y_os98(self) -> None:
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn("var contexto := _contexto_os98(dia)", fuente)
        self.assertIn('contexto["fase"] = String(dia.jornada.get("fase", "archivo"))', fuente)
        self.assertIn('contexto["acciones"] = int(dia.jornada.get("acciones"', fuente)
        self.assertIn('contexto["companeros"] = presentes.duplicate()', fuente)
        self.assertIn('dia.jornada.get("eventos", [])', fuente)
        self.assertNotIn("Time.get_", CLIENTE.read_text(encoding="utf-8"))

    def test_buscar_y_ejecutar_descubren_la_app(self) -> None:
        fuente = LANZADOR.read_text(encoding="utf-8")
        self.assertIn('"id": "chat-corporativo"', fuente)
        self.assertIn('"aliases": ["chat", "irc", "mensajeria"]', fuente)

    def test_interfaz_ejecutable_en_godot(self) -> None:
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
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
