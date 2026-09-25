import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
PROCEDENCIA = ROOT / "godot" / "assets" / "procedencia.json"
CARPETA = ROOT / "godot" / "assets" / "modelos" / "rocketbox"
COMPANEROS = ROOT / "godot" / "guion" / "companeros.gd"
PRESETS = ROOT / "godot" / "export_presets.cfg"
PRUEBA_GODOT = "pruebas/pruebas_personas_rocketbox.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


def _avatares():
    return sorted(CARPETA.glob("*.glb"))


class PersonasRocketboxTest(unittest.TestCase):
    def test_cada_companero_apunta_a_un_avatar_versionado(self):
        texto = COMPANEROS.read_text(encoding="utf-8")
        nombres = set(re.findall(r'"rocketbox/([a-z0-9_]+)"', texto))
        self.assertTrue(nombres)
        presentes = {avatar.stem for avatar in _avatares()}
        self.assertEqual(nombres, presentes)

    def test_avatares_son_rocketbox_mit_con_su_aviso(self):
        fichas = {
            ficha["ruta"]: ficha
            for ficha in json.loads(PROCEDENCIA.read_text(encoding="utf-8"))["assets"]
        }
        for avatar in _avatares():
            with self.subTest(avatar=avatar.name):
                ficha = fichas.get(f"modelos/rocketbox/{avatar.name}")
                self.assertIsNotNone(ficha)
                self.assertEqual(ficha["autor"], "Microsoft")
                self.assertEqual(ficha["licencia"], "MIT")
                self.assertIn("archivo_origen", ficha)
        # MIT exige que el aviso viaje con cada copia, también la exportada.
        aviso = CARPETA / "LICENSE-MIT.txt"
        self.assertIn("Copyright (c) 2020 Microsoft", aviso.read_text(encoding="utf-8"))
        filtros = re.findall(r'^include_filter="([^"]*)"', PRESETS.read_text(encoding="utf-8"), re.M)
        self.assertTrue(filtros)
        for filtro in filtros:
            self.assertIn("assets/**/LICENSE*.txt", filtro)

    def test_avatares_se_importan_con_perfil_humanoide_y_silueta(self):
        for avatar in _avatares():
            with self.subTest(avatar=avatar.name):
                texto = Path(f"{avatar}.import").read_text(encoding="utf-8")
                self.assertIn("SkeletonProfileHumanoid", texto)
                self.assertIn('&"Bip01 Pelvis"', texto)
                # Sin fix_silhouette los clips UAL retuercen los brazos del Biped.
                self.assertIn('"retarget/rest_fixer/fix_silhouette/enable": true', texto)

    def test_personas_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=120,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN_GODOT.search(resultado.stdout), resultado.stdout)
        # Un shader que no compila deja la figura sin material y la prueba de
        # contrato seguiría en verde; un material liberado antes que su
        # instancia solo se ve en el log.
        for error in ("SHADER ERROR", "Shader compilation failed", 'Parameter "material" is null'):
            self.assertNotIn(error, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
