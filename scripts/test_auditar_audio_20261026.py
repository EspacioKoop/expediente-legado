"""Tests sintéticos, offline, del auditor de audio de Godot (#2740)."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).with_name("auditar_audio_20261026.py")
spec = importlib.util.spec_from_file_location("auditor_audio", MODULE)
auditor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(auditor)


class AuditorAudioTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        (self.root / "godot" / "guion").mkdir(parents=True)
        (self.root / "godot" / "assets" / "audio").mkdir(parents=True)

    def put(self, path, content):
        file = self.root / "godot" / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(content, encoding="utf-8")
        return file

    def findings(self):
        return auditor.scan(self.root)["findings"]

    def codes(self):
        return sorted({f["code"] for f in self.findings()})

    def test_inventario_sano_no_reporta(self):
        self.put("guion/sonido.gd", 'const RUTA := "res://assets/audio/"\n')
        self.put("assets/audio/paso.ogg", "")
        self.put("assets/procedencia.json", json.dumps({"assets": [{"ruta": "audio/paso.ogg"}]}))
        self.put(
            "guion/escena.gd", 'var s = load("res://assets/audio/paso.ogg")\n'
        )
        self.assertEqual(self.findings(), [])

    def test_referencia_rota_tiene_fichero_y_linea(self):
        self.put(
            "guion/escena.gd", 'var s = load("res://assets/audio/ausente.ogg")\n'
        )
        rotos = [f for f in self.findings() if f["code"] == "audio_roto"]
        self.assertEqual(len(rotos), 1)
        self.assertEqual(rotos[0]["file"], "godot/guion/escena.gd")
        self.assertEqual(rotos[0]["line"], 1)
        self.assertEqual(rotos[0]["severity"], "error")

    def test_nombre_desnudo_se_resuelve_con_la_ruta_de_su_catalogo(self):
        self.put("guion/sonido.gd", 'const RUTA := "res://assets/audio/"\n"paso.ogg"\n')
        self.put("guion/musica.gd", 'const RUTA := "res://assets/audio/musica/"\n"final.ogg"\n')
        rotos = {f["detail"] for f in self.findings() if f["code"] == "audio_roto"}
        self.assertEqual(
            rotos,
            {
                "referencia sin fichero: res://assets/audio/paso.ogg",
                "referencia sin fichero: res://assets/audio/musica/final.ogg",
            },
        )

    def test_nombre_desnudo_fuera_de_catalogo_no_es_referencia(self):
        self.put("guion/otro.gd", '"paso.ogg"\n')
        self.assertNotIn("audio_roto", self.codes())

    def test_huerfano_es_aviso_no_error(self):
        self.put("guion/sonido.gd", 'const RUTA := "res://assets/audio/"\n')
        self.put("assets/audio/solo.ogg", "")
        huerfanos = [f for f in self.findings() if f["code"] == "audio_huerfano"]
        self.assertEqual(len(huerfanos), 1)
        self.assertEqual(huerfanos[0]["severity"], "warning")

    def test_procedencia_exige_ficha_en_las_dos_direcciones(self):
        self.put("guion/sonido.gd", 'const RUTA := "res://assets/audio/"\n"paso.ogg"\n')
        self.put("assets/audio/paso.ogg", "")
        self.put(
            "assets/procedencia.json",
            json.dumps({"assets": [{"ruta": "audio/otro.ogg"}]}),
        )
        codes = self.codes()
        self.assertIn("ficha_ausente", codes)
        self.assertIn("ficha_huerfana", codes)

    def test_clave_de_bucle_no_es_referencia_rota(self):
        self.put(
            "guion/musica.gd",
            'const RUTA := "res://assets/audio/musica/"\n'
            "const INICIO_BUCLE_POR_FICHERO := {\n"
            '\t"battle_music_01-loop.ogg": 7.5,\n'
            "}\n",
        )
        self.assertNotIn("audio_roto", self.codes())

    def test_solo_cuenta_extensiones_de_audio(self):
        self.put("guion/sonido.gd", 'const RUTA := "res://assets/audio/"\n')
        self.put("assets/audio/imagen.png", "")
        self.assertNotIn("audio_huerfano", self.codes())

    def test_json_salida_es_reproducible(self):
        self.put("assets/audio/solo.ogg", "")
        resumen = auditor.scan(self.root)
        self.assertEqual(resumen["hallazgos"], len(resumen["findings"]))
        self.assertEqual(resumen["ficheros_audio"], 1)

    def test_raiz_sin_godot_es_error(self):
        with tempfile.TemporaryDirectory() as vacio:
            with self.assertRaises(ValueError):
                auditor.scan(Path(vacio))


if __name__ == "__main__":
    unittest.main()
