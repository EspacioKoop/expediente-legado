import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "ecos_despertar.gd"
RUNTIME = ROOT / "godot" / "guion" / "ecos_despertar_runtime.gd"
DIA_REACTIVO = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
DIA_APP = ROOT / "godot" / "guion" / "dia_app.gd"
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
SUENO_COMBATE = ROOT / "godot" / "guion" / "sueno_combate.gd"
PRUEBA = "res://pruebas/pruebas_ecos_despertar_1775.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EcosDespertar1775Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = MODELO.read_text(encoding="utf-8")
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.dia_reactivo = DIA_REACTIVO.read_text(encoding="utf-8")
        cls.dia_app = DIA_APP.read_text(encoding="utf-8")
        cls.dia_gato = DIA_GATO.read_text(encoding="utf-8")
        cls.sueno_combate = SUENO_COMBATE.read_text(encoding="utf-8")

    def test_material_vivido_sale_de_presentacion_runtime(self):
        self.assertIn("static func material_desde_noche(", self.fuente)
        self.assertIn("MutadoresSueno.HUMEDAD", self.fuente)
        self.assertIn("MutadoresSueno.DESFASE", self.fuente)
        self.assertIn("\"monitor\"", self.fuente)
        self.assertIn("\"televisor_casa\"", self.fuente)
        self.assertIn("\"silla\"", self.fuente)
        self.assertIn("\"archivador\"", self.fuente)
        self.assertIn("\"armario_hogar\"", self.fuente)
        self.assertNotIn("SuenoFormas", self.fuente)
        self.assertNotIn("ObjetosOniricos", self.fuente)

    def test_captura_runtime_solo_mira_presentacion_montada(self):
        self.assertIn("class_name EcosDespertarRuntime", self.runtime)
        self.assertIn("SuenoMutadorPresentacion3D.NOMBRE", self.runtime)
        self.assertIn('get_meta("presentacion"', self.runtime)
        self.assertIn('get_meta("objeto_origen"', self.runtime)
        self.assertIn("EcosDespertar.material_desde_noche(", self.runtime)
        self.assertIn("EcosDespertar.candidatos(", self.runtime)
        self.assertNotIn("SuenoFormas", self.runtime)
        self.assertNotIn("ObjetosOniricos", self.runtime)
        self.assertNotIn("HuellasAmbientales", self.runtime)
        self.assertIn('CLAVE_PENDIENTE := "eco_despertar_pendiente"', self.runtime)
        self.assertIn("static func preparar_despertar(", self.runtime)
        self.assertRegex(self.runtime, r"EcosDespertar\s*\.\s*preparar\(")
        self.assertIn("EcosDespertar.vigente(", self.runtime)
        self.assertIn("jornada.erase(CLAVE_MATERIAL)", self.runtime)
        self.assertNotIn("EcosDespertar.presentacion(", self.runtime)

    def test_controller_registra_despues_de_montar_utileria(self):
        llamada = "EcosDespertarRuntime.registrar_sala(dia.jornada, mundo, anomalias)"
        self.assertIn(llamada, self.dia_reactivo)
        self.assertLess(
            self.dia_reactivo.index("SuenoUtileria"),
            self.dia_reactivo.index(llamada),
        )

    def test_cuatro_rutas_preparan_antes_de_despertar(self):
        preparar = r"EcosDespertarRuntime\.preparar_despertar\(jornada\)"
        self.assertEqual(2, len(re.findall(preparar, self.dia_app)))
        self.assertRegex(
            self.dia_app,
            preparar + r"\s+var dia := Jornada\.despertar\(jornada\)",
        )
        self.assertRegex(
            self.dia_app,
            preparar + r"\s+var dia := Jornada\.despertar_de_golpe\(jornada\)",
        )
        self.assertEqual(1, len(re.findall(preparar, self.dia_gato)))
        self.assertRegex(
            self.dia_gato,
            preparar + r"\s+dia_nuevo = Jornada\.despertar\(jornada\)",
        )
        self.assertEqual(1, len(re.findall(preparar, self.sueno_combate)))
        self.assertRegex(
            self.sueno_combate,
            preparar
            + r"\s+var dia_despertar := Jornada\.despertar_de_golpe\(jornada\)",
        )
        self.assertIn('"dia": dia_despertar', self.sueno_combate)

    def test_runtime_preparacion_es_idempotente_y_no_presenta(self):
        self.assertIn("EcosDespertar.vigente(previo, noche + 1)", self.runtime)
        self.assertIn("return previo.duplicate(true)", self.runtime)
        self.assertIn("jornada.erase(CLAVE_PENDIENTE)", self.runtime)
        self.assertIn("jornada[CLAVE_PENDIENTE] = pendiente.duplicate(true)", self.runtime)
        self.assertNotIn("EcosDespertar.presentacion(", self.runtime)
        self.assertNotIn("EcosDespertar.aceptar(", self.runtime)

    def test_catalogo_y_seleccion_son_acotados(self):
        for tipo in ("humedad", "crt", "objeto_desplazado", "sonido_residual"):
            self.assertIn(f'"{tipo}"', self.fuente)
        self.assertIn('Azar.derivar(raiz, "sueno", [noche, 1775])', self.fuente)
        self.assertIn('"dia_vigilia": noche + 1', self.fuente)
        self.assertIn('"consumido": false', self.fuente)

    def test_no_es_otra_fuente_de_estado_global(self):
        for simbolo in (
            "Partida.",
            "Jornada.",
            "HuellasAmbientales",
            "Expediente",
            "dinero",
            "pista",
            "veredicto",
            "combate",
        ):
            self.assertNotIn(simbolo, self.fuente)

    def test_consumo_requiere_aceptacion_del_consumidor(self):
        bloque_oferta = self.fuente.split("static func oferta(", 1)[1].split(
            "static func aceptar(", 1
        )[0]
        self.assertNotIn('"consumido"] = true', bloque_oferta)
        bloque_aceptar = self.fuente.split("static func aceptar(", 1)[1].split(
            "static func descartar_al_avanzar(", 1
        )[0]
        self.assertIn('estado["consumido"] = true', bloque_aceptar)
        self.assertIn('eco_id != String(estado.get("id", ""))', bloque_aceptar)

    def test_reduccion_movimiento_no_cambia_logica(self):
        bloque = self.fuente.split("static func presentacion(", 1)[1]
        self.assertIn('"estilo": "corte" if reduccion_movimiento else "transicion"', bloque)
        self.assertNotIn('pendiente["consumido"] =', bloque)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
