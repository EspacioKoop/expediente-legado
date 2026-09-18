from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VERTICAL = ROOT / "godot" / "guion" / "sueno_ecos_archivo_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_ecos_archivo_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class EcosArchivoRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vertical = VERTICAL.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.controller_compact = "".join(cls.controller.split())
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_vertical_es_3d_visible_y_usa_interaccion_comun(self):
        self.assertIn("class_name SuenoEcosArchivo3D", self.vertical)
        self.assertIn("extends Node3D", self.vertical)
        self.assertIn("Interactuable3D.new()", self.vertical)
        self.assertIn("Label3D.new()", self.vertical)
        self.assertIn("BoxMesh.new()", self.vertical)
        self.assertIn("activado.connect(_al_activar_eco.bind(slot))", self.vertical)
        self.assertIn("EcosArchivoPresentacion.EVENTO_COMPLETADO", self.vertical)
        self.assertIn("_recompensa_texto", self.vertical)
        self.assertNotIn("Input.", self.vertical)
        self.assertNotIn("JOY_BUTTON_", self.vertical)
        self.assertNotIn("KEY_", self.vertical)

    def test_tres_ecos_no_crean_barrera_fisica(self):
        self.assertIn("POSICIONES_ECOS := [", self.vertical)
        inicio = self.vertical.find("POSICIONES_ECOS := [")
        fin = self.vertical.find("]\n", inicio)
        self.assertEqual(self.vertical.count("Vector3(", inicio, fin), 3)
        for cuerpo_solido in ("StaticBody3D", "CharacterBody3D", "NavigationObstacle3D"):
            self.assertNotIn(cuerpo_solido, self.vertical)
        self.assertIn("CollisionShape3D.new()", self.vertical)
        self.assertIn("var eco := Interactuable3D.new()", self.vertical)

    def test_controller_solo_deriva_recompensas_de_documentos_leidos(self):
        self.assertIn('dia.jornada.get("leido_hoy",[])', self.controller_compact)
        self.assertIn('dia.partida.estado.get("pistas_descubiertas",[])', self.controller_compact)
        self.assertIn('pista.get("registroOrigen","")', self.controller_compact)
        self.assertIn('pista.get("fraseGatillo","")', self.controller_compact)
        self.assertIn('registro.get("contenido","")', self.controller_compact)
        self.assertIn(".contains(frase)", self.controller_compact)
        self.assertIn('pista.has("registroOrigen2")', self.controller_compact)
        self.assertIn('candidato.get("reward_id","")', self.controller_compact)
        self.assertIn("EcosArchivo.crear(", self.controller_compact)
        self.assertIn("EcosArchivoPresentacion.crear(ecos)", self.controller_compact)

    def test_controller_conecta_recompensa_real_y_prioriza_pendientes(self):
        self.assertIn("pendientesifnotpendientes.is_empty()elseconocidas", self.controller_compact)
        self.assertIn("dia.conectar_recompensa_onirica(ecos.nucleo,caso)", self.controller_compact)
        self.assertIn('candidato.get("descripcion","")', self.controller_compact)

    def test_determinismo_y_reduccion_movimiento_vienen_de_contratos_existentes(self):
        self.assertIn("Sueno.semilla(", self.controller_compact)
        self.assertIn('candidatos.sort_custom(Callable(self,"_candidato_antes"))', self.controller_compact)
        self.assertIn("posmod(semilla,candidatos.size())", self.controller_compact)
        self.assertIn(
            'PreferenciasSiga.cargar().get("reduccion_movimiento",false)',
            self.controller_compact,
        )

    def test_abandona_al_salir_de_la_sala_y_no_toca_veredicto(self):
        self.assertIn("_abandonar_si_procede()", self.controller)
        self.assertIn("_ecos_activos.abandonar()", self.controller)
        self.assertNotIn("Acusacion.", self.controller)
        self.assertNotIn('partida.estado["veredictos"] =', self.controller)
        self.assertNotIn("Jornada.fichar_salida", self.controller)
        self.assertNotIn("Jornada.despertar", self.controller)

    def test_controller_esta_montado_en_dia_real(self):
        self.assertIn('path="res://guion/dia_ecos_archivo_app.gd"', self.dia)
        self.assertIn('[node name="EcosArchivoController" type="Node" parent="."]', self.dia)


if __name__ == "__main__":
    unittest.main()
