import re
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class DiaExtResourcesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.escena = DIA.read_text(encoding="utf-8")
        cls.ext = re.findall(
            r'^\[ext_resource\b[^\n]*\bid="([^"]+)"\]$',
            cls.escena,
            flags=re.MULTILINE,
        )

    def test_ids_de_ext_resource_son_unicos(self) -> None:
        self.assertEqual(
            len(self.ext),
            len(set(self.ext)),
            "dia.tscn no puede declarar dos ext_resource con el mismo id",
        )

    def test_todas_las_referencias_externas_estan_declaradas(self) -> None:
        declarados = set(self.ext)
        usados = set(re.findall(r'ExtResource\("([^"]+)"\)', self.escena))
        self.assertFalse(
            usados - declarados,
            f"ExtResource sin declarar: {sorted(usados - declarados)}",
        )

    def test_load_steps_cubre_recursos_declarados(self) -> None:
        cabecera = re.search(r"^\[gd_scene load_steps=(\d+)\b", self.escena)
        self.assertIsNotNone(cabecera)
        subrecursos = re.findall(
            r"^\[sub_resource\b",
            self.escena,
            flags=re.MULTILINE,
        )
        self.assertEqual(
            int(cabecera.group(1)),
            1 + len(self.ext) + len(subrecursos),
        )

    def test_maui_y_reloj_conservan_scripts_distintos(self) -> None:
        recursos = {
            path: resource_id
            for path, resource_id in re.findall(
                r'^\[ext_resource\b[^\n]*path="([^"]+)"[^\n]*id="([^"]+)"\]$',
                self.escena,
                flags=re.MULTILINE,
            )
        }
        maui = recursos["res://guion/dia_maui_tamanuitera_app.gd"]
        reloj = recursos["res://guion/dia_reloj_horario_app.gd"]
        self.assertNotEqual(maui, reloj)

        self.assertRegex(
            self.escena,
            rf'\[node name="MauiTamanuiteraController"[^\n]*\]\n'
            rf'script = ExtResource\("{re.escape(maui)}"\)',
        )
        self.assertRegex(
            self.escena,
            rf'\[node name="RelojHorarioController"[^\n]*\]\n'
            rf'script = ExtResource\("{re.escape(reloj)}"\)',
        )


if __name__ == "__main__":
    unittest.main()
