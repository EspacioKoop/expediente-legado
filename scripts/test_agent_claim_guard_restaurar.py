import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from scripts.agent_claim_guard import restaurar_fuera_del_claim


class TestAgentClaimGuardRestaurar(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name).resolve()
        subprocess.run(["git", "init", "-q"], cwd=self.repo, check=True)
        subprocess.run(
            ["git", "config", "user.email", "test@example.invalid"],
            cwd=self.repo,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "Test"],
            cwd=self.repo,
            check=True,
        )
        (self.repo / "trackeado.txt").write_text("contenido base\n", encoding="utf-8")
        (self.repo / "otro_trackeado.txt").write_text("otro base\n", encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=self.repo, check=True)
        subprocess.run(["git", "commit", "-qm", "commit inicial"], cwd=self.repo, check=True)

    def tearDown(self):
        self.tmp.cleanup()

    def test_restaura_fichero_trackeado_modificado(self):
        (self.repo / "trackeado.txt").write_text("modificado fuera del claim\n", encoding="utf-8")
        restaurar_fuera_del_claim(self.repo, ["trackeado.txt"])
        self.assertEqual(
            (self.repo / "trackeado.txt").read_text(encoding="utf-8"),
            "contenido base\n",
        )

    def test_elimina_fichero_no_trackeado(self):
        fichero_nuevo = self.repo / "nuevo_no_trackeado.txt"
        fichero_nuevo.write_text("basura\n", encoding="utf-8")
        self.assertTrue(fichero_nuevo.exists())

        restaurar_fuera_del_claim(self.repo, ["nuevo_no_trackeado.txt"])
        self.assertFalse(fichero_nuevo.exists())

    def test_elimina_directorio_no_trackeado_completo(self):
        directorio_nuevo = self.repo / "dir_fuera"
        (directorio_nuevo / "sub").mkdir(parents=True)
        (directorio_nuevo / "archivo.txt").write_text("x\n", encoding="utf-8")
        (directorio_nuevo / "sub" / "archivo2.txt").write_text("y\n", encoding="utf-8")

        restaurar_fuera_del_claim(self.repo, ["dir_fuera"])
        self.assertFalse(directorio_nuevo.exists())

    def test_elimina_fichero_no_trackeado_y_poda_padres_vacios(self):
        fichero_anidado = self.repo / "a" / "b" / "c" / "anidado.txt"
        fichero_anidado.parent.mkdir(parents=True)
        fichero_anidado.write_text("dato\n", encoding="utf-8")

        restaurar_fuera_del_claim(self.repo, ["a/b/c/anidado.txt"])
        self.assertFalse(fichero_anidado.exists())
        self.assertFalse((self.repo / "a").exists())

    def test_elimina_symlink_no_trackeado_sin_afectar_destino(self):
        with tempfile.TemporaryDirectory() as temp_externo:
            destino_externo = Path(temp_externo) / "objetivo.txt"
            destino_externo.write_text("intacto\n", encoding="utf-8")

            enlace = self.repo / "enlace_externo"
            enlace.symlink_to(destino_externo)

            restaurar_fuera_del_claim(self.repo, ["enlace_externo"])

            self.assertFalse(enlace.exists())
            self.assertFalse(enlace.is_symlink())
            self.assertTrue(destino_externo.exists())
            self.assertEqual(destino_externo.read_text(encoding="utf-8"), "intacto\n")

    def test_conserva_ficheros_dentro_del_claim(self):
        (self.repo / "trackeado.txt").write_text("dentro del claim (modificado)\n", encoding="utf-8")
        (self.repo / "otro_trackeado.txt").write_text("fuera del claim (modificado)\n", encoding="utf-8")
        untracked_dentro = self.repo / "untracked_dentro.txt"
        untracked_dentro.write_text("nuevo dentro\n", encoding="utf-8")
        untracked_fuera = self.repo / "untracked_fuera.txt"
        untracked_fuera.write_text("nuevo fuera\n", encoding="utf-8")

        restaurar_fuera_del_claim(self.repo, ["otro_trackeado.txt", "untracked_fuera.txt"])

        self.assertEqual(
            (self.repo / "trackeado.txt").read_text(encoding="utf-8"),
            "dentro del claim (modificado)\n",
        )
        self.assertTrue(untracked_dentro.exists())
        self.assertEqual(
            (self.repo / "otro_trackeado.txt").read_text(encoding="utf-8"),
            "otro base\n",
        )
        self.assertFalse(untracked_fuera.exists())

    def test_lanza_error_si_ruta_escapa_del_repositorio(self):
        with self.assertRaises(ValueError):
            restaurar_fuera_del_claim(self.repo, ["../escapar.txt"])


if __name__ == "__main__":
    unittest.main()
