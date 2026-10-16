import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import textwrap
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
PRESENTACION = ROOT / "godot" / "guion" / "dia_presentacion_app.gd"
RESUMEN = re.compile(r"dia_presentacion_rotulos_1761: (\d+) pasadas, 0 fallos")


def funcion(nombre: str, fuente: str) -> str:
    patron = rf"(?ms)^func {re.escape(nombre)}\(.*?(?=^func |\Z)"
    match = re.search(patron, fuente)
    if match is None:
        raise AssertionError(f"no se encontró {nombre}")
    return match.group(0)


def normalizar_accesos(fuente: str) -> str:
    return re.sub(r"\s*\.\s*", ".", fuente)


class DiaPresentacionRotulos1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")

    def test_dia_conserva_wrappers_y_delega_rotulos(self):
        refrescar = normalizar_accesos(funcion("_refrescar_rotulos", self.dia))
        texto = normalizar_accesos(funcion("_texto_de_rotulo", self.dia))
        self.assertIn("_presentacion.refrescar_rotulo(", refrescar)
        self.assertIn("_rotulo", refrescar)
        self.assertIn("jornada", refrescar)
        self.assertIn('Callable(self, "tr")', refrescar)
        self.assertIn("return _presentacion.texto_de_rotulo(jornada, sitio, Callable(self, \"tr\"))", texto)
        self.assertNotIn('tr("DIA_ROTULO")', texto)
        self.assertNotIn('jornada["gato"]', texto)

    def test_helper_compone_texto_con_las_claves_actuales(self):
        helper = normalizar_accesos(funcion("texto_de_rotulo", self.presentacion))
        self.assertIn('traducir.call("DIA_ROTULO")', helper)
        self.assertIn('traducir.call("DIA_SIN_GATO")', helper)
        self.assertIn('jornada.get("dia", 1)', helper)
        self.assertIn('jornada.get("dinero", 0)', helper)
        self.assertIn('gato.get("presente", true)', helper)

    def test_refresco_ui_degrada_sin_label_ni_recursos_3d(self):
        refrescar = normalizar_accesos(funcion("refrescar_rotulo", self.presentacion))
        compacto = "".join(refrescar.split())
        self.assertIn("rotulo:Label", compacto)
        self.assertIn("ifrotulo==null:", compacto)
        self.assertIn("rotulo.text=texto_de_rotulo(", compacto)
        for prohibido in (
            "ESCENA_CAMINANTE",
            "montar_entorno(",
            "CharacterBody3D",
            "WorldEnvironment",
            "DirectionalLight3D",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, refrescar)

    def test_helper_no_toma_responsabilidades_de_dominio(self):
        for prohibido in (
            "Partida.",
            "Jornada.",
            "_guardar_o_avisar",
            "_entrar_en(",
            "Combate",
            "DIA_TRANSICION_APP",
            "EspaciosCatalogo",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, self.presentacion)

    def test_contrato_ui_en_godot_sin_montar_escena_3d(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        script = textwrap.dedent(
            """
            extends SceneTree

            const Presentacion := preload("res://guion/dia_presentacion_app.gd")

            var _pasadas := 0
            var _fallos := 0

            func _init() -> void:
            	call_deferred("_ejecutar")

            func _ejecutar() -> void:
            	var presentacion := Presentacion.new()
            	var con_gato := {"dia": 7, "dinero": 23, "gato": {"presente": true}}
            	var sin_gato := {"dia": 8, "dinero": 5, "gato": {"presente": false}}
            	var rotulo := Label.new()
            	root.add_child(rotulo)
            	presentacion.refrescar_rotulo(rotulo, con_gato, "Archivo", Callable(self, "_tr"))
            	_comprobar(rotulo.text == "Día 7 · Archivo · ₧23", "refresca label con gato presente")
            	_comprobar(
            		presentacion.texto_de_rotulo(sin_gato, "Casa", Callable(self, "_tr"))
            		== "Día 8 · Casa · ₧5 · sin gato",
            		"compone aviso de gato ausente",
            	)
            	presentacion.refrescar_rotulo(null, sin_gato, "Casa", Callable(self, "_tr"))
            	_comprobar(true, "refrescar sin Label no falla")
            	rotulo.queue_free()
            	await process_frame
            	print("dia_presentacion_rotulos_1761: %d pasadas, %d fallos" % [_pasadas, _fallos])
            	quit(1 if _fallos > 0 else 0)

            func _tr(clave: String) -> String:
            	match clave:
            		"DIA_ROTULO":
            			return "Día %d · %s · ₧%d%s"
            		"DIA_SIN_GATO":
            			return " · sin gato"
            		_:
            			return clave

            func _comprobar(condicion: bool, mensaje: String) -> void:
            	_pasadas += 1
            	if condicion:
            		return
            	_fallos += 1
            	push_error("FALLO #1761 rótulos: %s" % mensaje)
            """
        )
        with tempfile.NamedTemporaryFile(
            "w", suffix="_dia_presentacion_rotulos_1761.gd", dir=ROOT / "godot", encoding="utf-8", delete=False
        ) as temporal:
            temporal.write(script)
            script_path = Path(temporal.name)
        try:
            resultado = subprocess.run(
                [motor, "--headless", "--path", str(ROOT / "godot"), "--script", str(script_path)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )
        finally:
            script_path.unlink(missing_ok=True)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        assert resumen is not None
        self.assertGreaterEqual(int(resumen.group(1)), 3, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
