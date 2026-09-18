from pathlib import Path
import json
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "bolos_pasillo_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_bolos_pasillo_app.gd"
SCENE = ROOT / "godot" / "escenas" / "bolos_pasillo.tscn"
DIA_SCENE = ROOT / "godot" / "escenas" / "dia.tscn"
GODOT_TEST = ROOT / "godot" / "pruebas" / "pruebas_bolos_pasillo_3d.gd"
SELLOS = ROOT / "godot" / "datos" / "sellos.json"


class BolosPasillo3DTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")
        self.controller = CONTROLLER.read_text(encoding="utf-8")
        self.scene = SCENE.read_text(encoding="utf-8")
        self.dia_scene = DIA_SCENE.read_text(encoding="utf-8")
        self.godot_test = GODOT_TEST.read_text(encoding="utf-8")
        self.sellos = json.loads(SELLOS.read_text(encoding="utf-8"))

    def test_vertical_consumidor_del_nucleo_sin_partida(self):
        self.assertIn("class_name BolosPasillo3D", self.source)
        self.assertIn("extends Node3D", self.source)
        self.assertIn("Bolos.nueva(LANZADORES)", self.source)
        self.assertIn("Bolos.derribar(estado, nuevos)", self.source)
        self.assertNotIn("Partida", self.source)
        self.assertNotIn("RigidBody3D.new(", self.source)
        self.assertNotIn("extends RigidBody3D", self.source)

    def test_pista_tiene_diez_bolos_y_simulacion_acotada(self):
        bloque = re.search(
            r"const POSICIONES_BOLOS := \[(.*?)\n\]",
            self.source,
            flags=re.DOTALL,
        )
        self.assertIsNotNone(bloque)
        self.assertEqual(10, bloque.group(1).count("Vector3("))
        self.assertIn("const PASO_FIJO := 1.0 / 120.0", self.source)
        self.assertIn("const TIEMPO_MAXIMO_TIRO := 4.0", self.source)
        self.assertIn("simular_hasta_reposo", self.source)

    def test_variantes_rotan_sin_estado_persistente_ni_texto_nuevo(self):
        for variante in ("estrecho", "mesa", "rebote", "absurdo", "nocturno"):
            self.assertIn(f'VARIANTE_{variante.upper() if variante != "absurdo" else "ABSURDO"}', self.source)
        self.assertIn("static func ancho_de", self.source)
        self.assertIn("static func posiciones_de", self.source)
        self.assertIn("static func obstaculo_de", self.source)
        self.assertIn("static func energia_luz_de", self.source)
        self.assertIn("static func variante_para_dia", self.controller)
        self.assertIn("sesion.configurar_variante", self.controller)
        self.assertNotIn("partida.estado[\"variante_bolos\"]", self.controller)
        self.assertIn("la mesa bloquea un lanzamiento", self.godot_test)
        self.assertIn("el archivador devuelve la bola", self.godot_test)
        self.assertIn("el cuñado desplaza un bolo a una posición absurda", self.godot_test)
        self.assertIn("la ronda nocturna reduce la iluminación", self.godot_test)

    def test_companeros_reutilizan_animacion_de_134_sin_entrar_en_fisica(self):
        self.assertIn("CompaneroIdle3D.new()", self.source)
        self.assertIn('Modelos.persona(cuerpo, "persona"', self.source)
        self.assertIn('get("reduccion_movimiento", false)', self.source)
        self.assertIn("POSICIONES_COMPANEROS", self.source)
        self.assertIn("los compañeros reutilizan idle de oficina", self.godot_test)
        self.assertIn("los compañeros quedan fuera de la física del carril", self.godot_test)
        self.assertNotIn("AnimacionesUAL.reproducir", self.source)
        for tipo_fisico in ("CharacterBody3D.new(", "StaticBody3D.new(", "RigidBody3D.new("):
            self.assertNotIn(tipo_fisico, self.source)

    def test_entrada_es_semantica_y_valida_para_mando(self):
        self.assertIn(
            'Input.get_axis("mover_izquierda", "mover_derecha")',
            self.source,
        )
        self.assertIn('Input.is_action_just_pressed("interactuar")', self.source)
        self.assertIn('Input.is_action_just_pressed("cancelar")', self.source)
        self.assertIn("PreferenciasSiga.aplicar(PreferenciasSiga.cargar())", self.source)
        self.assertNotRegex(self.source, r"KEY_[A-Z0-9_]+")

    def test_escena_y_regresion_ejecutable_quedan_versionadas(self):
        self.assertIn('path="res://guion/bolos_pasillo_3d.gd"', self.scene)
        self.assertIn('load("res://escenas/bolos_pasillo.tscn")', self.godot_test)
        self.assertIn("simular_hasta_reposo()", self.godot_test)
        self.assertIn("fallar no bloquea el turno", self.godot_test)
        self.assertIn("abandonar devuelve resultado válido", self.godot_test)

    def test_integracion_es_opcional_y_premia_sin_acoplar_el_vertical(self):
        self.assertIn("class_name DiaBolosPasilloApp", self.controller)
        self.assertIn('String(jornada.get("fase", "")) != "archivo"', self.controller)
        self.assertIn("PERIODO_DIAS := 3", self.controller)
        self.assertIn("posmod(dia - DIA_INICIAL, PERIODO_DIAS)", self.controller)
        self.assertIn("Interactuable3D.new()", self.controller)
        self.assertNotIn("Partida", self.source)
        self.assertIn('SELLO_RECOMPENSA := "pasillo-en-regla"', self.controller)
        self.assertIn("Sellos.registrar_sello", self.controller)
        self.assertIn('dia.call("_guardar_o_avisar", "")', self.controller)
        self.assertNotIn("Economia.", self.controller)
        self.assertNotIn("Acusacion.", self.controller)

    def test_sello_de_bolos_esta_catalogado_y_la_regresion_cubre_idempotencia(self):
        ids = [entrada["id"] for entrada in self.sellos]
        self.assertIn("pasillo-en-regla", ids)
        self.assertIn("abandonar no concede el sello", self.godot_test)
        self.assertIn("recargar conserva el sello", self.godot_test)
        self.assertIn("repetir la actividad no duplica el sello", self.godot_test)

    def test_integracion_suspende_y_restaura_el_mundo(self):
        self.assertIn("Node.PROCESS_MODE_DISABLED", self.controller)
        self.assertIn('get_node_or_null("/root/MenuGlobal")', self.controller)
        self.assertIn("set_process_unhandled_input(false)", self.controller)
        self.assertIn("ultimo_resultado_bolos", self.controller)
        self.assertIn("_restaurar_presentacion()", self.controller)
        self.assertIn("abandonar restaura el mundo", self.godot_test)
        self.assertIn("terminar devuelve a la oficina", self.godot_test)

    def test_marcador_final_es_visual_breve_y_no_bloquea(self):
        self.assertIn("DURACION_MARCADOR := 3.5", self.controller)
        self.assertIn("func _mostrar_marcador(resultado: Dictionary)", self.controller)
        self.assertIn('if bool(resultado.get("completa", false)):', self.controller)
        self.assertIn("etiqueta.text = str(int(puntuaciones[indice])).pad_zeros(2)", self.controller)
        self.assertIn("ColorRect.new()", self.controller)
        self.assertIn("Control.MOUSE_FILTER_IGNORE", self.controller)
        self.assertIn("temporizador.one_shot = true", self.controller)
        self.assertIn("abandonar no muestra marcador final", self.godot_test)
        self.assertIn("el marcador enseña las cuatro puntuaciones", self.godot_test)

    def test_dia_monta_el_controller_sin_tocar_la_raiz(self):
        self.assertIn(
            'path="res://guion/dia_bolos_pasillo_app.gd"',
            self.dia_scene,
        )
        self.assertIn('[node name="BolosPasilloController" type="Node" parent="."]', self.dia_scene)
        self.assertIn('script = ExtResource("1")', self.dia_scene)

    def test_regresion_queda_en_verificador_canonico(self):
        verificador = (ROOT / "scripts" / "verificar_godot.py").read_text(encoding="utf-8")
        self.assertIn('"bolos-pasillo"', verificador)
        self.assertIn(
            '["--script", "pruebas/pruebas_bolos_pasillo_3d.gd"]',
            verificador,
        )


if __name__ == "__main__":
    unittest.main()
