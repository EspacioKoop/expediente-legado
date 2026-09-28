import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESTRES = ROOT / "godot" / "guion" / "estres.gd"
MARCADORES = ROOT / "godot" / "guion" / "dia_marcadores_mundo_app.gd"
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
HUD = ROOT / "godot" / "guion" / "dia_hud_fases_app.gd"
INDICADOR = ROOT / "godot" / "guion" / "estres_hud_indicador.gd"
ENTORNO = ROOT / "godot" / "guion" / "estres_ambiental.gd"
AVIONES = ROOT / "godot" / "guion" / "aviones_papel_descanso.gd"
GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
ARCHIVADO = ROOT / "godot" / "guion" / "dia_archivado_app.gd"
SMOKE = "pruebas/issue_952_smoke.gd"


class Estres952Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.estres = ESTRES.read_text(encoding="utf-8")
        cls.marcadores = MARCADORES.read_text(encoding="utf-8")
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.hud = HUD.read_text(encoding="utf-8")
        cls.indicador = INDICADOR.read_text(encoding="utf-8")
        cls.entorno = ENTORNO.read_text(encoding="utf-8")
        cls.aviones = AVIONES.read_text(encoding="utf-8")
        cls.gato = GATO.read_text(encoding="utf-8")
        cls.archivado = ARCHIVADO.read_text(encoding="utf-8")

    def test_estado_interno_y_acotado_vive_en_jornada(self):
        self.assertIn('const CAMPO_JORNADA := "estres_dinamico"', self.estres)
        self.assertIn("clampf(anterior + delta, 0.0, VALOR_MAXIMO)", self.estres)
        self.assertIn("static func nivel(jornada: Dictionary) -> float:", self.estres)
        self.assertNotIn("Partida", self.estres)
        self.assertNotIn("ProgressBar", self.estres)
        self.assertNotIn("TextureProgressBar", self.estres)

    def test_hud_expone_indicador_visual_sin_texto_de_estado(self):
        self.assertIn('"estres_segmentos": segmentos_estres(Estres.nivel(jornada))', self.hud)
        self.assertIn('preload("res://guion/estres_hud_indicador.gd")', self.hud)
        self.assertIn('fila.add_child(_indicador_estres)', self.hud)
        self.assertNotIn("Estres.valor(", self.hud)
        for palabra in ("CALMA", "INQUIETUD", "TENSIÓN", "PARANOIA"):
            self.assertNotIn(palabra, self.hud)
        self.assertIn("draw_arc(", self.indicador)
        self.assertIn("draw_circle(", self.indicador)
        self.assertIn("const SEGMENTOS := 4", self.indicador)
        self.assertNotIn("Label", self.indicador)
        self.assertNotIn("ProgressBar", self.indicador)
        self.assertNotIn("TextureProgressBar", self.indicador)

    def test_catalogo_cubre_tension_y_recuperacion_sin_bloqueos(self):
        for evento in (
            "documento_sensible",
            "oscuridad",
            "fallo_critico",
            "sonido_inquietante",
            "zona_segura",
            "autocuidado",
            "resolucion",
        ):
            self.assertIn(f'"{evento}"', self.estres)
        for termino_prohibido in ("game_over", "bloquear", "vida -=", "acciones -="):
            self.assertNotIn(termino_prohibido, self.estres.lower())

    def test_marcadores_consumen_la_fuente_canonica_sin_duplicarla(self):
        self.assertIn("Estres.nivel(_host.jornada)", self.marcadores)
        self.assertIn("_estres_presentacion", self.marcadores)
        self.assertIn(
            "visual.configurar(datos, en_sueno, _estres_presentacion)",
            self.marcadores,
        )
        self.assertNotIn('jornada["estres_dinamico"]', self.marcadores)

    def test_visor_convierte_lectura_confidencial_en_productor_real(self):
        bloque = self.visor.split("func _al_elegir_documento", 1)[1].split(
            "func _mostrar_registro", 1
        )[0]
        evento = 'Estres.aplicar(jornada, "documento_sensible")'
        self.assertIn('if bool(caso.get("confidencial", false)):', bloque)
        self.assertIn(evento, bloque)
        self.assertLess(bloque.index("Jornada.gastar_lectura"), bloque.index(evento))
        self.assertLess(bloque.index("Jornada.anotar_lectura"), bloque.index(evento))
        self.assertNotIn('jornada["estres_dinamico"]', bloque)

    def test_ambiente_consume_el_nivel_canonico(self):
        self.assertIn('"estres": Estres.nivel(jornada)', self.dia)
        self.assertNotIn('jornada["estres_dinamico"]', self.dia)

    def test_exposicion_ambiental_es_temporal_y_usa_la_luz_real(self):
        self.assertIn("INTERVALO_SEGUNDOS := 60.0", self.entorno)
        self.assertIn('return "oscuridad"', self.entorno)
        self.assertIn('return "zona_segura"', self.entorno)
        self.assertIn('if fase == "sueño":', self.entorno)
        self.assertIn("_ambiente.ambient_light_energy", self.dia)
        self.assertIn("Jornada.hora_decimal(jornada)", self.dia)
        self.assertIn("EstresAmbiental.INTENSIDAD", self.dia)

    def test_cambiar_de_fase_reinicia_la_exposicion_y_modales_no_cuentan(self):
        self.assertIn("_reiniciar_temporizador_estres_entorno()", self.dia)
        self.assertIn("partida.guardado_pendiente or _pantalla != null or _entrada != null", self.dia)
        self.assertIn("is_instance_valid(_dialogo_actual)", self.dia)
        self.assertIn("not _caminante.is_physics_processing()", self.dia)
        self.assertIn('_guardar_o_avisar("")', self.dia)

    def test_descanso_de_aviones_es_productor_real_de_autocuidado(self):
        self.assertIn('Estres.aplicar(jornada, "autocuidado")', self.aviones)
        self.assertIn('if not ya_jugado:', self.aviones)
        abandono = self.aviones.index('if resultado.get("abandonada", false):')
        autocuidado = self.aviones.index('Estres.aplicar(jornada, "autocuidado")')
        self.assertLess(abandono, autocuidado)

    def test_puzzle_onirico_completado_aplica_resolucion_una_vez(self):
        bloque = self.gato.split(
            "func _actualizar_objetivo_puzzle_onirico", 1
        )[1].split("func ", 1)[0]
        completar = "SuenoObjetivos.completar(estado, objetivo_id)"
        resolucion = 'Estres.aplicar(jornada, "resolucion")'
        self.assertIn(completar, bloque)
        self.assertIn(resolucion, bloque)
        self.assertLess(bloque.index(completar), bloque.index(resolucion))
        self.assertLess(bloque.index(resolucion), bloque.index("_tras_cambio_objetivo"))
        self.assertIn("if not " + completar + ":", bloque)

    def test_archivado_incorrecto_es_productor_real_de_fallo_critico(self):
        bloque = self.archivado.split("func _archivar_en", 1)[1].split(
            "func _sincronizar_desorden_espacial", 1
        )[0]
        self.assertIn('Estres.aplicar(host.jornada, "fallo_critico")', bloque)
        self.assertIn("if not correcta and registrada and primer_error:", bloque)
        self.assertIn("func _caso_tiene_error_previo", self.archivado)

    def test_smoke_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                SMOKE,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("issue_952:", resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
