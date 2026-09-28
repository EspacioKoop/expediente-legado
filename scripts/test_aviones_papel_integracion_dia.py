import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "godot" / "guion" / "dia_aviones_papel_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
SELLOS = ROOT / "godot" / "datos" / "sellos.json"


def sin_comentarios(fuente):
    return "\n".join(linea.split("#", 1)[0] for linea in fuente.splitlines())


class AvionesPapelIntegracionDiaTest(unittest.TestCase):
    def setUp(self):
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.dia = DIA.read_text(encoding="utf-8")
        self.textos = TEXTOS.read_text(encoding="utf-8")
        self.sellos = json.loads(SELLOS.read_text(encoding="utf-8"))

    def test_dia_monta_el_controller(self):
        self.assertIn('path="res://guion/dia_aviones_papel_app.gd"', self.dia)
        self.assertIn('[node name="AvionesPapelController"', self.dia)

    def test_oferta_tiene_rotulo_traducible(self):
        self.assertIn('AVIONES_TITULO,Aviones de papel', self.textos)
        self.assertIn('tr("AVIONES_TITULO")', self.controller)

    def test_reutiliza_disponibilidad_y_escena_de_jornada(self):
        self.assertIn(
            'preload("res://escenas/minijuego_aviones_papel_jornada.tscn")',
            self.controller,
        )
        self.assertIn("AvionesPapelDescanso.disponible(dia.jornada)", self.controller)
        self.assertIn('sesion.call("configurar_jornada", dia.jornada)', self.controller)
        self.assertIn('connect("finalizada", Callable(self, "_al_terminar"))', self.controller)

    def test_oferta_es_fisica_y_no_consume_hasta_jugar(self):
        self.assertIn("var oferta := Interactuable3D.new()", self.controller)
        self.assertIn("POSICION_OFERTA", self.controller)
        codigo = sin_comentarios(self.controller)
        self.assertNotIn("AvionesPapelDescanso.marcar_jugado", codigo)

    def test_pausa_no_toca_economia(self):
        codigo = sin_comentarios(self.controller)
        for prohibido in (
            "Jornada.gastar_accion",
            'jornada["acciones"]',
            'jornada["dinero"]',
            "Economia.",
            "Acusacion.",
        ):
            self.assertNotIn(prohibido, codigo)

    def test_completar_concede_sello_cosmetico_y_abandonar_no(self):
        self.assertIn(
            'SELLO_RECOMPENSA := "trayectoria-reglamentaria"',
            self.controller,
        )
        self.assertIn(
            'if bool(resultado.get("completa", false)):\n\t\t_registrar_recompensa(dia)',
            self.controller,
        )
        bloque_cierre = self.controller.split("func _cerrar_sesion", 1)[1].split(
            "func _registrar_recompensa", 1
        )[0]
        self.assertNotIn('resultado.get("abandonada"', bloque_cierre)
        self.assertIn("Sellos.registrar_sello", self.controller)

    def test_sello_usa_partida_y_guardado_canonicos_de_forma_idempotente(self):
        bloque = self.controller.split("func _registrar_recompensa", 1)[1].split(
            "func _mostrar_comentario", 1
        )[0]
        self.assertIn('dia.get("partida")', bloque)
        self.assertIn('partida.get("estado")', bloque)
        self.assertIn("Sellos.registrar_sello(estado, SELLO_RECOMPENSA)", bloque)
        self.assertIn('resultado in ["registrado", "ya-obtenido"]', bloque)
        self.assertIn('dia.call("_guardar_o_avisar", "")', bloque)

        fichas = {entrada["id"]: entrada for entrada in self.sellos}
        ficha = fichas["trayectoria-reglamentaria"]
        self.assertEqual("aviones-papel", ficha["origen"])
        self.assertTrue(ficha["disponible"])
        self.assertEqual(
            "SELLO_TRAYECTORIA_REGLAMENTARIA_TITULO",
            ficha["titulo"],
        )
        self.assertEqual(
            "SELLO_TRAYECTORIA_REGLAMENTARIA_DESCRIPCION",
            ficha["descripcion"],
        )
        self.assertIn(
            "SELLO_TRAYECTORIA_REGLAMENTARIA_TITULO,Trayectoria reglamentaria",
            self.textos,
        )
        self.assertIn(
            "SELLO_TRAYECTORIA_REGLAMENTARIA_DESCRIPCION,"
            "Ronda de aviones de papel completada y asentada sin incidencia "
            "en el registro interno.",
            self.textos,
        )

    def test_companeros_reutilizan_sistema_134_sin_entrar_en_fisica(self):
        self.assertIn("POSICIONES_COMPANEROS", self.controller)
        self.assertIn('Modelos.persona(cuerpo, "persona"', self.controller)
        self.assertIn("CompaneroIdle3D.new()", self.controller)
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertIn('get("reduccion_movimiento", false)', self.controller)
        self.assertIn("_retirar_companeros()", self.controller)

        bloque = self.controller.split("func _montar_companeros", 1)[1].split(
            "func _retirar_companeros", 1
        )[0]
        self.assertIn("var cuerpo := Node3D.new()", bloque)
        self.assertNotIn("AnimacionesUAL.reproducir", bloque)
        for tipo_fisico in (
            "CharacterBody3D.new(",
            "StaticBody3D.new(",
            "RigidBody3D.new(",
            "CollisionShape3D.new(",
        ):
            self.assertNotIn(tipo_fisico, bloque)

    def test_restaura_control_y_presenta_comentario_seguro(self):
        self.assertIn("Node.PROCESS_MODE_DISABLED", self.controller)
        self.assertIn("Input.MOUSE_MODE_VISIBLE", self.controller)
        self.assertIn("_restaurar_presentacion()", self.controller)
        self.assertIn('resultado.get("descanso", {})', self.controller)


if __name__ == "__main__":
    unittest.main()
