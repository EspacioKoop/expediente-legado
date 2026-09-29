import csv
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIALOGO = ROOT / "godot" / "guion" / "dialogo_religion_933.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
TELEFONO = ROOT / "godot" / "guion" / "telefono_fijo.gd"
TELEFONO_PANEL = ROOT / "godot" / "guion" / "telefono_fijo_panel.gd"
DIA_TELEFONO = ROOT / "godot" / "guion" / "dia_telefono_fijo_app.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
PRUEBA_GODOT = "res://pruebas/pruebas_dialogo_religion_933.gd"


class DialogoReligion933Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.dialogo = DIALOGO.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.telefono = TELEFONO.read_text(encoding="utf-8")
        cls.telefono_panel = TELEFONO_PANEL.read_text(encoding="utf-8")
        cls.dia_telefono = DIA_TELEFONO.read_text(encoding="utf-8")
        with TEXTOS.open(encoding="utf-8", newline="") as archivo:
            cls.textos = {fila["clave"]: fila["es"] for fila in csv.DictReader(archivo)}

    def test_dos_interlocutores_consumen_canales_distintos(self) -> None:
        self.assertIn("ACTOR_CUNADO", self.dialogo)
        self.assertIn("ACTOR_CORRESPONDENCIA", self.dialogo)
        self.assertIn("ReligionEventos.CANAL_EXPOSICION", self.dialogo)
        self.assertIn("ReligionEventos.CANAL_PRACTICA", self.dialogo)
        self.assertIn("ReligionEventos.CANAL_CONVICCION", self.dialogo)
        self.assertNotIn("ReligionEventos.CANAL_VINCULO", self.dialogo)

    def test_conocimiento_es_explicito_y_limitado_a_la_vuelta(self) -> None:
        self.assertIn('evento.get("publico", false)', self.dialogo)
        self.assertIn('evento.get("conocido_por", [])', self.dialogo)
        self.assertIn("ReligionEventos.eventos_de_vuelta(", self.dialogo)

    def test_conviccion_tiene_variantes_por_interlocutor(self) -> None:
        self.assertIn("CLAVE_CUNADO_CONVICCION", self.dialogo)
        self.assertIn("CLAVE_CORRESPONDENCIA_CONVICCION", self.dialogo)
        self.assertIn("_prioridades_para(", self.dialogo)

    def test_oficina_propaga_id_estable_y_conserva_dialogo_base(self) -> None:
        self.assertIn('companero.set_meta("id_companero"', self.dia)
        self.assertIn('companero.get_meta("id_companero", "")', self.dia)
        self.assertIn("DialogoReligion933.resolver_clave(", self.dia)
        self.assertIn("return clave_dialogo", self.dia)
        self.assertIn("DialogoIdeologico.SUPERFICIE_OFICINA_CUNADO", self.dia)

    def test_paco_conserva_ramas_y_reaccion_religiosa_es_secundaria(self) -> None:
        self.assertIn('ACTOR_PACO := "paco"', self.dialogo)
        self.assertIn('get_meta("religion_933_mostrada", false)', self.dia)
        self.assertIn("DialogoDependientesContextual.tiene_ramas(id_dependiente)", self.dia)
        self.assertIn("DialogoReligion933.resolver_clave(partida.estado, id_dependiente)", self.dia)
        self.assertLess(
            self.dia.index("DialogoDependientesContextual.tiene_ramas(id_dependiente)"),
            self.dia.index('get_meta("religion_933_mostrada", false)'),
        )

    def test_telefono_recibe_estado_read_only_y_solo_contextualiza_contacto_declarado(self) -> None:
        self.assertIn('"id": "centro_comunitario"', self.telefono)
        self.assertIn('"religion_actor": DialogoReligion933.ACTOR_TELEFONO_COMUNITARIO', self.telefono)
        self.assertIn("var estado_partida: Dictionary = {}", self.telefono_panel)
        self.assertIn("DialogoReligion933.resolver_clave(estado_partida, actor_religion)", self.telefono_panel)
        self.assertIn("_panel.estado_partida = estado_partida as Dictionary", self.dia_telefono)
        self.assertNotIn("ReligionEventos.registrar(", self.telefono_panel)
        self.assertNotIn("ReligionEventos.registrar(", self.dia_telefono)

    def test_no_toca_progreso_ni_economia(self) -> None:
        combinado = self.dialogo
        for termino in (
            "pistas_descubiertas",
            "veredictos",
            "dinero",
            "acciones",
            "Estres.aplicar",
            "registrar(",
        ):
            self.assertNotIn(termino, combinado)

    def test_textos_visibles_estan_catalogados(self) -> None:
        for clave in (
            "RELIGION_933_CUNADO_EXPOSICION",
            "RELIGION_933_CORRESPONDENCIA_PRACTICA",
            "RELIGION_933_CUNADO_CONVICCION",
            "RELIGION_933_CORRESPONDENCIA_CONVICCION",
            "RELIGION_933_PACO_EXPOSICION",
            "RELIGION_933_PACO_PRACTICA",
            "RELIGION_933_PACO_CONVICCION",
            "RELIGION_933_TELEFONO_EXPOSICION",
            "RELIGION_933_TELEFONO_PRACTICA",
            "RELIGION_933_TELEFONO_CONVICCION",
        ):
            self.assertIn(clave, self.textos)
            self.assertTrue(self.textos[clave].strip())

    def test_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")
        with tempfile.TemporaryDirectory(prefix="religion-933-") as temporal:
            entorno = os.environ.copy()
            for variable, carpeta in (
                ("XDG_DATA_HOME", "datos"),
                ("XDG_CONFIG_HOME", "config"),
                ("XDG_CACHE_HOME", "cache"),
            ):
                entorno[variable] = str(Path(temporal) / carpeta)
            resultado = subprocess.run(
                [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
