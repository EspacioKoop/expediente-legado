from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
PERFIL = RAIZ / "godot/guion/perfil_jugador.gd"
CUERPO = RAIZ / "godot/guion/cuerpo_jugador_3d.gd"
CREADOR = RAIZ / "godot/guion/creador_personaje_app.gd"
CAMINANTE = RAIZ / "godot/escenas/caminante.tscn"
INICIO = RAIZ / "godot/guion/inicio_app.gd"


class ProtagonistaConfigurableTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.perfil = PERFIL.read_text()
        cls.cuerpo = CUERPO.read_text()
        cls.creador = CREADOR.read_text()
        cls.caminante = CAMINANTE.read_text()
        cls.inicio = INICIO.read_text()

    def test_hay_tres_complexiones_reutilizables(self):
        for nombre in ("delgado", "medio", "robusto"):
            self.assertIn(f'"{nombre}"', self.perfil)

    def test_hay_seis_trasfondos_y_son_narrativos(self):
        ids = (
            "auxiliar_administrativo",
            "almacen_fabrica",
            "informatica_autodidacta",
            "estudiante_nocturno",
            "cuidados_familiares",
            "recien_llegado",
        )
        for identificador in ids:
            self.assertIn(f'"{identificador}"', self.perfil)
        self.assertIn('"etiquetas"', self.perfil)
        self.assertNotIn('"bono"', self.perfil)
        self.assertNotIn('"bonus"', self.perfil)

    def test_perfil_es_persistente_y_normalizado(self):
        self.assertIn('user://perfil_jugador.json', self.perfil)
        self.assertIn('static func completar', self.perfil)
        self.assertIn('static func guardar', self.perfil)
        self.assertIn('clampf(float(apariencia.get("altura"', self.perfil)

    def test_cuerpo_es_visual_y_no_crea_colisiones(self):
        self.assertIn("BoxMesh.new()", self.cuerpo)
        self.assertIn("CapsuleMesh.new()", self.cuerpo)
        self.assertIn("SphereMesh.new()", self.cuerpo)
        self.assertIn("CylinderMesh.new()", self.cuerpo)
        self.assertNotIn("CollisionShape3D", self.cuerpo)
        self.assertNotIn("CharacterBody3D", self.cuerpo)

    def test_caminante_monta_el_cuerpo_sin_cambiar_su_capsula(self):
        self.assertIn('path="res://guion/cuerpo_jugador_3d.gd"', self.caminante)
        self.assertIn('[node name="CuerpoJugador3D" type="Node3D" parent="."]', self.caminante)
        self.assertIn("radius = 0.35", self.caminante)
        self.assertIn("height = 1.7", self.caminante)

    def test_editor_expone_aspecto_y_trasfondo(self):
        for texto in ("Complexión", "Altura visual", "Tono de piel", "Peinado", "Prenda", "Antes de SIGA"):
            self.assertIn(texto, self.creador)
        self.assertIn("PerfilJugador.TRASFONDOS", self.creador)
        self.assertIn("PerfilJugador.guardar", self.creador)

    def test_editor_es_accesible_desde_inicio(self):
        self.assertIn("Crear / editar personaje", self.inicio)
        self.assertIn("res://escenas/creador_personaje.tscn", self.inicio)


if __name__ == "__main__":
    unittest.main()
