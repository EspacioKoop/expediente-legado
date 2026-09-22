import json
from pathlib import Path
import re
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot/datos/puntos_inspeccion.json"
PASAPORTE = ROOT / "godot/guion/pasaporte_inspeccion.gd"
RUNTIME = ROOT / "godot/guion/pasaporte_inspeccion_runtime.gd"
PRUEBA = ROOT / "godot/pruebas/pruebas_pasaporte_inspeccion_condiciones_154.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PasaporteInspeccionCondiciones154Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        cls.pasaporte = PASAPORTE.read_text(encoding="utf-8")
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.prueba = PRUEBA.read_text(encoding="utf-8")

    def test_catalogo_resuelve_anclas_sin_coordenadas_duplicadas(self):
        tipos = {entrada["ancla_tipo"] for entrada in self.catalogo}
        self.assertEqual(tipos, {"bulto_rol", "nodo_prefijo", "nodo"})
        self.assertNotIn("Vector3", CATALOGO.read_text(encoding="utf-8"))
        peine = next(entrada for entrada in self.catalogo if entrada["id"] == "sueno:peine")
        self.assertEqual(peine["forma"], "peine")
        self.assertEqual(peine["ancla"], "LuzDeSala")

    def test_condiciones_se_derivan_de_fuentes_existentes(self):
        for token in (
            "Jornada.franja_horaria(jornada)",
            "Clima.estado(int(jornada.get(\"dia\", 1)))",
            'int(jornada.get("vuelta", 1)) > 1',
            'not bool(gato.get("presente", true))',
        ):
            self.assertIn(token, self.pasaporte)
        self.assertNotIn("Time.get_", self.pasaporte)
        self.assertNotIn("RandomNumberGenerator", self.pasaporte)

    def test_variantes_comparten_persistencia_y_son_idempotentes(self):
        self.assertIn("SEPARADOR_VARIANTE", self.pasaporte)
        self.assertIn("estado.get(Sellos.CLAVE_ESTADO, [])", self.pasaporte)
        self.assertIn('"variantes_nuevas": nuevas', self.pasaporte)
        self.assertIn('"cambio":', self.pasaporte)
        self.assertNotIn('FileAccess.open("user://', self.pasaporte)

    def test_contexto_exige_la_zona_real(self):
        self.assertIn('String(jornada.get("fase", "")) != zona', self.pasaporte)
        self.assertIn('"resultado": "zona-invalida"', self.pasaporte)

    def test_runtime_usa_interaccion_comun_y_guarda_solo_cambios(self):
        self.assertIn("class_name DiaPasaporteInspeccionApp", self.runtime)
        self.assertIn("PuntoInspeccion3D.new()", self.runtime)
        self.assertIn("CollisionShape3D.new()", self.runtime)
        self.assertIn("SphereShape3D.new()", self.runtime)
        self.assertIn("punto.observado.connect(_al_observar.bind(dia))", self.runtime)
        self.assertIn("PasaporteInspeccion.registrar_observacion_contextual", self.runtime)
        self.assertIn('if not bool(registro.get("cambio", false)):', self.runtime)
        self.assertIn('dia.call("_guardar_o_avisar", "")', self.runtime)

    def test_runtime_no_toca_economia_pistas_ni_input(self):
        for prohibido in (
            'jornada["dinero"]',
            'jornada["acciones"]',
            'estado["pistas_descubiertas"]',
            "Input.",
            "DetectorInteraccion3D.new()",
        ):
            self.assertNotIn(prohibido, self.runtime)

    def test_tras_sueno_no_se_finge_sin_hecho_persistente(self):
        self.assertIn('"Tras salir del sueño" queda fuera', self.pasaporte)
        self.assertNotIn('"tras-sueno"', self.pasaporte)

    def test_contrato_ejecutable_en_godot(self):
        resultado = ejecutar_script("pruebas/pruebas_pasaporte_inspeccion_condiciones_154.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 30, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
