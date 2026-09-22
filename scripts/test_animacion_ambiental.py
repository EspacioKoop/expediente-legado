"""Capa común de animación ambiental (#1230): contrato y prueba real en Godot."""
from pathlib import Path
import os
import re
import subprocess
import tempfile
import unittest

from verificar_godot import validar


RAIZ = Path(__file__).resolve().parents[1]
GUION = RAIZ / "godot/guion"
ARTE = RAIZ / "godot/arte"


def _leer(ruta):
    return ruta.read_text(encoding="utf-8")


def _codigo(ruta):
    """Solo el código: un contrato no puede cumplirse por nombrarlo en un comentario."""
    lineas = []
    for linea in _leer(ruta).splitlines():
        sin_comentario = re.sub(r"(^|\s)#.*$", "", linea)
        if sin_comentario.strip():
            lineas.append(sin_comentario)
    return "\n".join(lineas)


class AnimacionAmbientalTest(unittest.TestCase):
    """El reparto: presupuesto, LOD, atención y despertar."""

    @classmethod
    def setUpClass(cls):
        cls.planificador = _codigo(GUION / "animacion_ambiental.gd")
        cls.animador = _leer(GUION / "animador_ambiental_3d.gd")

    def test_el_planificador_no_depende_de_godot_en_ejecucion(self):
        self.assertIn("extends RefCounted", self.planificador)
        self.assertNotIn("_process", self.planificador)
        self.assertNotIn("get_tree()", self.planificador)
        self.assertNotIn("Time.", self.planificador)

    def test_declara_presupuesto_y_cortes_de_lod(self):
        for contrato in (
            "PRESUPUESTO := 24",
            "DISTANCIA_CERCA := 18.0",
            "DISTANCIA_MEDIA := 36.0",
            "DISTANCIA_LEJOS := 72.0",
        ):
            self.assertIn(contrato, self.planificador)

    def test_los_cortes_de_lod_coinciden_con_los_de_fachadas_vivas(self):
        """Animar con más detalle del que se dibuja no lo ve nadie (#861)."""
        fachadas = _leer(GUION / "calle_fachadas_vivas.gd")
        for nuestro, suyo in (
            ("DISTANCIA_CERCA := 18.0", "LOD_CERCA_FIN := 18.0"),
            ("DISTANCIA_MEDIA := 36.0", "LOD_MEDIA_FIN := 36.0"),
            ("DISTANCIA_LEJOS := 72.0", "LOD_LEJOS_FIN := 72.0"),
        ):
            self.assertIn(nuestro, self.planificador)
            self.assertIn(suyo, fachadas)

    def test_el_animador_pasa_el_tiempo_acumulado_y_no_el_delta(self):
        """Es lo que permite dormir una pieza sin que pierda el hilo."""
        self.assertRegex(
            self.animador,
            r"METODO_PIEZA,\s*id,\s*_tiempo,\s*transcurrido,",
        )
        self.assertRegex(self.animador, r"transcurrido\s*:=\s*_tiempo\s*-\s*float\(")

    def test_el_animador_es_avanzable_sin_arbol_de_escena(self):
        self.assertRegex(self.animador, r"func avanzar\(delta: float\)")
        self.assertRegex(self.animador, r"func _process\(delta: float\) -> void:\s*\n\s*avanzar")

    def test_una_pieza_muerta_no_rompe_el_reparto(self):
        self.assertIn("is_instance_valid(destino)", self.animador)


class EfectosDeVerticeTest(unittest.TestCase):
    """Viento y respiración viven en el shader y empiezan apagados."""

    @classmethod
    def setUpClass(cls):
        cls.psx = _leer(ARTE / "psx.gdshader")

    def test_apagados_por_defecto(self):
        """Lo que no opte por el efecto tiene que dibujarse exactamente igual."""
        self.assertIn("uniform float viento_fuerza = 0.0;", self.psx)
        self.assertIn("uniform float respiracion_fuerza = 0.0;", self.psx)
        self.assertIn("if (viento_fuerza > 0.0) {", self.psx)
        self.assertIn("if (respiracion_fuerza > 0.0) {", self.psx)

    def test_el_balanceo_deja_quieta_la_base(self):
        """Un árbol se mece por la copa; si se mece por el tronco, flota."""
        self.assertRegex(self.psx, r"rampa\s*=\s*clamp\(VERTEX\.y\s*/")
        self.assertRegex(self.psx, r"VERTEX\.xz\s*\+=.*rampa;")

    def test_la_respiracion_no_toca_la_colision(self):
        """Va en el vértice a propósito: no puede reabrir #784."""
        self.assertRegex(self.psx, r"VERTEX\s*\+=\s*NORMAL\s*\*\s*pulso")
        respiracion = _codigo(GUION / "sueno_respiracion.gd")
        for prohibido in ("CollisionShape", "StaticBody", "global_position ="):
            self.assertNotIn(prohibido, respiracion)

    def test_el_follaje_es_opt_in(self):
        """Una farola con el mismo shader no puede empezar a mecerse sola."""
        viento = _leer(GUION / "viento_ambiental.gd")
        self.assertIn('GRUPO_FOLLAJE := "follaje_viento"', viento)
        self.assertIn("is_in_group(GRUPO_FOLLAJE)", viento)
        arboles = _leer(ARTE / "arboles_quaternius.gd")
        self.assertIn("add_to_group(VientoAmbiental.GRUPO_FOLLAJE)", arboles)

    def test_la_respiracion_deja_en_paz_el_suelo(self):
        respiracion = _leer(GUION / "sueno_respiracion.gd")
        self.assertIn("ALTURA_MINIMA := 1.5", respiracion)
        self.assertRegex(respiracion, r"get_aabb\(\)\.size\.y\s*>=\s*ALTURA_MINIMA")
        self.assertRegex(respiracion, r"func soltar\(\)")


class VentanasVivasTest(unittest.TestCase):
    """El barrio cambia de luz sin multiplicar el coste."""

    @classmethod
    def setUpClass(cls):
        cls.ventanas = _codigo(GUION / "calle_ventanas_vivas.gd")
        cls.shader = _leer(ARTE / "ventana_viva.gdshader")
        cls.calle = _leer(GUION / "dia_calle_app.gd")

    def test_una_sola_llamada_de_dibujo(self):
        self.assertIn("MultiMesh.new()", self.ventanas)
        self.assertIn("use_custom_data = true", self.ventanas)
        self.assertEqual(self.ventanas.count("MultiMeshInstance3D.new()"), 1)

    def test_el_parpadeo_lo_calcula_la_tarjeta(self):
        """Escribir un parpadeo de tele desde CPU son miles de escrituras."""
        self.assertIn("INSTANCE_CUSTOM", self.shader)
        self.assertIn("TIME", self.shader)
        self.assertNotIn("TIME", self.ventanas)

    def test_no_toca_la_capa_de_fachadas_vivas(self):
        """#861 tiene que seguir siendo retirable sin arrastrar esto."""
        self.assertNotIn("CalleFachadasVivas", self.ventanas)
        self.assertIn('get_node_or_null("FachadasVivas")', self.ventanas)

    def test_el_estado_de_una_ventana_es_funcion_del_tiempo(self):
        self.assertRegex(self.ventanas, r"func estado_en\(indice: int, tiempo: float")
        self.assertNotIn("randi", self.ventanas)
        self.assertNotIn("randf", self.ventanas)

    def test_solo_una_parte_del_barrio_se_mueve(self):
        self.assertIn("PASO_SELECCION := 3", self.ventanas)
        self.assertIn("MAX_VENTANAS := 18", self.ventanas)

    def test_la_calle_registra_sus_piezas_en_el_animador_del_dia(self):
        self.assertRegex(self.calle, r"animador\s*:=\s*animador_ambiental\(\)")
        self.assertIn("CalleVentanasVivas.new()", self.calle)
        self.assertIn("VientoAmbiental.new()", self.calle)

    def test_el_animador_es_uno_por_dia(self):
        """Dos animadores serían dos presupuestos y ningún techo."""
        sueno = _leer(GUION / "dia_sueno_app.gd")
        self.assertIn("func animador_ambiental()", sueno)
        self.assertNotIn("AnimadorAmbiental3D.new()", self.calle)
        self.assertEqual(sueno.count("AnimadorAmbiental3D.new()"), 1)

    def test_cambiar_de_fase_suelta_lo_registrado(self):
        sueno = _leer(GUION / "dia_sueno_app.gd")
        self.assertIn("soltar_animacion_ambiental()", sueno)
        self.assertRegex(sueno, r"func soltar_animacion_ambiental\(\)")
        self.assertIn("_soltar_capas_calle()", self.calle)


class AnimacionAmbientalEnGodotTest(unittest.TestCase):
    """El montaje real sobre la calle, que ningún texto puede demostrar."""

    def test_animacion_de_la_calle_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="animacion-ambiental-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(RAIZ / "godot")]
            for argumentos, importando in [
                (["--editor", "--import", "--quit"], True),
                (["--script", "res://pruebas/pruebas_animacion_calle_1230.gd"], False),
            ]:
                resultado = subprocess.run(
                    base + argumentos,
                    env=entorno,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    timeout=240,
                    check=False,
                )
                try:
                    validar(resultado.stdout, resultado.returncode, None, importando)
                except ValueError as error:
                    self.fail(f"{error}\n{resultado.stdout}")
                if not importando:
                    resumen = re.search(r"(\d+) pasadas, (\d+) fallos", resultado.stdout)
                    self.assertIsNotNone(resumen, resultado.stdout)
                    self.assertEqual(int(resumen.group(2)), 0, resultado.stdout)
                    self.assertGreaterEqual(int(resumen.group(1)), 18, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
