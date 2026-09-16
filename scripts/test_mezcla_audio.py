import json
from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


RAIZ = Path(__file__).resolve().parents[1]
PROYECTO = RAIZ / "godot" / "project.godot"
LAYOUT = RAIZ / "godot" / "default_bus_layout.tres"
ROUTER = RAIZ / "godot" / "guion" / "mezcla_audio.gd"
PREFERENCIAS = RAIZ / "godot" / "guion" / "preferencias_siga.gd"
TEXTOS = RAIZ / "godot" / "datos" / "mezcla_audio_textos.json"


class MezclaAudioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")
        cls.layout = LAYOUT.read_text(encoding="utf-8")
        cls.router = ROUTER.read_text(encoding="utf-8")
        cls.preferencias = PREFERENCIAS.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))

    def test_layout_declara_tres_buses_separados_hacia_master(self):
        for nombre in ("Efectos", "Ambiente", "Musica"):
            with self.subTest(nombre=nombre):
                self.assertIn(f'&"{nombre}"', self.layout)
        self.assertEqual(self.layout.count('send = &"Master"'), 3)
        self.assertEqual(self.layout.count("volume_db = 0.0"), 3)

    def test_router_esta_activo_desde_el_arranque(self):
        self.assertIn('MezclaAudio="*res://guion/mezcla_audio.gd"', self.proyecto)
        self.assertIn("get_tree().node_added.connect(_al_anadir_nodo)", self.router)

    def test_router_cubre_reproductores_2d_3d_y_normales(self):
        self.assertIn("nodo is AudioStreamPlayer", self.router)
        self.assertIn("nodo is AudioStreamPlayer2D", self.router)
        self.assertIn("nodo is AudioStreamPlayer3D", self.router)
        self.assertIn('const BUS_EFECTOS := &"Efectos"', self.router)
        self.assertIn('const BUS_AMBIENTE := &"Ambiente"', self.router)
        self.assertIn('const BUS_MUSICA := &"Musica"', self.router)

    def test_mixer_se_monta_dentro_de_opciones_sin_segunda_persistencia(self):
        self.assertIn('call_deferred("_montar_mixer_opciones")', self.router)
        self.assertIn('bloque.name = "MixerAudio"', self.router)
        self.assertIn('menu.get("_volumen") as HSlider', self.router)
        self.assertIn('menu.get("_preferencias")', self.router)
        self.assertIn('titulo.text = _texto("seccion")', self.router)
        self.assertIn('etiqueta.text = _texto(String(control["texto"]))', self.router)
        self.assertIn('RUTA_TEXTOS := "res://datos/mezcla_audio_textos.json"', self.router)
        self.assertEqual(
            self.textos,
            {
                "seccion": "Mezcla",
                "efectos": "Efectos",
                "ambiente": "Ambiente",
                "musica": "Música",
            },
        )
        self.assertIn("PreferenciasSiga.guardar(_preferencias)", self.router)
        self.assertNotIn("user://", self.router)

    def test_mixer_aplica_master_y_subniveles_por_nombre_de_bus(self):
        self.assertIn("func aplicar_volumenes(preferencias: Dictionary)", self.router)
        self.assertIn("AudioServer.get_bus_index(bus)", self.router)
        self.assertIn("AudioServer.set_bus_volume_db", self.router)
        self.assertIn("AudioServer.set_bus_mute", self.router)
        for clave in ("volumen_efectos", "volumen_ambiente", "volumen_musica"):
            self.assertIn(f'"{clave}"', self.preferencias)
            self.assertIn(f'"{clave}"', self.router)

    def test_contrato_runtime_se_ejecuta_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_mezcla_audio.gd",
            "18 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
