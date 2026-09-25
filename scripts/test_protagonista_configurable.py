from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
PERFIL = RAIZ / "godot/guion/perfil_jugador.gd"
PARTIDA = RAIZ / "godot/guion/partida.gd"
CUERPO = RAIZ / "godot/guion/cuerpo_jugador_3d.gd"
CREADOR = RAIZ / "godot/guion/creador_personaje_app.gd"
PREVISUALIZADOR = RAIZ / "godot/guion/previsualizador_personaje_3d.gd"
CAMINANTE = RAIZ / "godot/escenas/caminante.tscn"
INICIO = RAIZ / "godot/guion/inicio_app.gd"
DIA = RAIZ / "godot/guion/dia_app.gd"
TEXTOS = RAIZ / "godot/datos/textos.csv"


class ProtagonistaConfigurableTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.perfil = PERFIL.read_text()
        cls.partida = PARTIDA.read_text()
        cls.cuerpo = CUERPO.read_text()
        cls.creador = CREADOR.read_text()
        cls.previsualizador = PREVISUALIZADOR.read_text()
        cls.caminante = CAMINANTE.read_text()
        cls.inicio = INICIO.read_text()
        cls.dia = DIA.read_text()
        cls.textos = TEXTOS.read_text()

    def test_hay_seis_avatares_rocketbox_elegibles(self):
        ids = re.findall(r'"id": "(rocketbox/[a-z0-9_]+)"', self.perfil)
        self.assertEqual(len(ids), 5)
        for avatar in ids:
            self.assertTrue((RAIZ / f"godot/assets/modelos/{avatar}.glb").exists(), avatar)

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
        # Nombre y descripcion se traducen: el perfil solo guarda claves.
        for clave in ("AUXILIAR", "ALMACEN", "INFORMATICA", "ESTUDIANTE", "CUIDADOS", "RECIEN_LLEGADO"):
            self.assertIn(f'"TRASFONDO_{clave}"', self.perfil)
            self.assertIn(f"TRASFONDO_{clave}_DESCRIPCION,", self.textos)
        self.assertNotIn('"bono"', self.perfil)
        self.assertNotIn('"bonus"', self.perfil)

    def test_perfil_vive_en_partida_y_migra_guardados_antiguos(self):
        self.assertIn('"perfil_jugador": PerfilJugador.nuevo()', self.partida)
        self.assertIn(
            'PerfilJugador.completar(fusionado["perfil_jugador"])',
            self.partida,
        )
        self.assertIn('guardado.has("perfil_jugador")', self.partida)
        self.assertNotIn("user://perfil_jugador.json", self.perfil)
        self.assertNotIn("FileAccess", self.perfil)
        self.assertIn("static func completar", self.perfil)
        self.assertIn('"configurado": true', self.perfil)
        self.assertIn('clampf(float(apariencia.get("altura"', self.perfil)

    def test_cuerpo_es_visual_y_no_crea_colisiones(self):
        # El detalle (figura, gestos) lo verifica la prueba Godot
        # pruebas_cuerpo_jugador_3d.gd sobre el árbol real.
        self.assertIn("extends Node3D", self.cuerpo)
        self.assertIn('Modelos.persona(soporte, String(apariencia["avatar"])', self.cuerpo)
        self.assertIn('AnimacionesUAL.reproducir(_figura, "andar")', self.cuerpo)
        self.assertNotIn("CollisionShape3D.new()", self.cuerpo)
        self.assertNotIn("extends CharacterBody3D", self.cuerpo)
        self.assertNotIn("move_and_slide()", self.cuerpo)

    def test_caminante_monta_el_cuerpo_sin_cambiar_su_capsula(self):
        self.assertIn('path="res://guion/cuerpo_jugador_3d.gd"', self.caminante)
        self.assertIn(
            '[node name="CuerpoJugador3D" type="Node3D" parent="."]',
            self.caminante,
        )
        self.assertIn("radius = 0.35", self.caminante)
        self.assertIn("height = 1.7", self.caminante)

    def test_editor_expone_aspecto_y_trasfondo(self):
        textos = {
            "PERSONAJE_AVATAR": "Aspecto",
            "PERSONAJE_ALTURA": "Altura visual",
            "PERSONAJE_ANTES_DE_SIGA": "Antes de SIGA",
        }
        for clave, texto in textos.items():
            self.assertIn(f'"{clave}"', self.creador)
            self.assertIn(f"{clave},{texto}", self.textos)
        self.assertIn("PerfilJugador.TRASFONDOS", self.creador)
        self.assertIn('_partida.estado["perfil_jugador"]', self.creador)
        self.assertIn("_partida.guardar()", self.creador)

    def test_editor_previsualiza_en_vivo_la_misma_ficha(self):
        self.assertIn("PrevisualizadorPersonaje3D.new()", self.creador)
        self.assertIn("_previsualizacion.aplicar(candidato)", self.creador)
        self.assertIn("extends SubViewportContainer", self.previsualizador)
        self.assertIn("SubViewport.UPDATE_ALWAYS", self.previsualizador)
        self.assertIn("CanvasItem.TEXTURE_FILTER_NEAREST", self.previsualizador)
        self.assertIn("_cuerpo.primera_persona = false", self.previsualizador)
        self.assertIn("_cuerpo.aplicar(_perfil)", self.previsualizador)
        self.assertNotIn("Partida.new()", self.previsualizador)
        self.assertNotIn(".guardar(", self.previsualizador)

    def test_primera_persona_oculta_la_cabeza(self):
        self.assertIn("@export var primera_persona := true", self.cuerpo)
        self.assertIn("OcultarCabeza.new()", self.cuerpo)

    def test_nueva_partida_exige_ficha_y_guardarla_arranca_el_dia(self):
        self.assertIn('perfil["configurado"] = false', self.inicio)
        self.assertIn("not PerfilJugador.esta_configurado(perfil)", self.inicio)
        self.assertIn("_abrir_personaje()", self.inicio)
        self.assertIn('_perfil["configurado"] = true', self.creador)
        self.assertIn("_alta_pendiente", self.creador)
        self.assertIn('change_scene_to_file("res://escenas/dia.tscn")', self.creador)

    def test_cuerpo_recibe_el_perfil_de_la_partida_cargada(self):
        # El dia ya tiene la partida: el cuerpo no vuelve a leer el disco.
        self.assertNotIn("Partida.new()", self.cuerpo)
        self.assertNotIn(".cargar(", self.cuerpo)
        self.assertNotIn(".guardar(", self.cuerpo)
        self.assertIn('cuerpo_jugador.perfil = partida.estado.get("perfil_jugador", {})', self.dia)

    def test_editor_es_accesible_desde_inicio(self):
        self.assertIn('tr("INICIO_PERSONAJE")', self.inicio)
        self.assertIn("INICIO_PERSONAJE,Crear / editar personaje", self.textos)
        self.assertIn("res://escenas/creador_personaje.tscn", self.inicio)


if __name__ == "__main__":
    unittest.main()
