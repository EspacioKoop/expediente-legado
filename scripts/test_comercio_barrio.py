import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
COMERCIO = ROOT / "godot" / "guion" / "comercio_barrio.gd"
DOC = ROOT / "docs" / "comercio-barrio.md"
PRUEBA_TABACO = "pruebas/pruebas_comercio_tabaco.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class ComercioBarrioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.comercio = COMERCIO.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_tres_superficies_diferenciadas(self):
        for superficie in ('"quiosco"', '"videojuegos"', '"segunda_mano"'):
            self.assertIn(superficie, self.comercio)
        self.assertIn("const SUPERFICIES", self.comercio)

    def test_reutiliza_economia_existente(self):
        self.assertIn("Jornada.gastar(jornada, precio)", self.comercio)
        compra = self.comercio.split("static func comprar", 1)[1].split(
            "static func vender", 1
        )[0]
        self.assertNotIn('jornada["acciones"]', compra)
        self.assertNotIn('jornada["cerrados_hoy"]', compra)

    def test_videojuegos_delega_en_contrato_existente(self):
        self.assertIn("TiendaVideojuegos.listar(jornada)", self.comercio)
        self.assertIn("TiendaVideojuegos.comprar(jornada, item_id)", self.comercio)
        self.assertNotIn("user://roms", self.comercio)

    def test_segunda_mano_materializa_en_home_storage(self):
        self.assertIn('"destino": "home_storage"', self.comercio)
        self.assertIn("Inventario.recoger(inventario, objeto)", self.comercio)
        self.assertIn("Inventario.guardar_en_casa(inventario, item_id)", self.comercio)

    def test_reventa_conecta_inventario_y_saldo_sin_teletransportar_casa(self):
        self.assertIn("static func vender(", self.comercio)
        venta = self.comercio.split("static func vender", 1)[1].split(
            "static func fuente_cultural", 1
        )[0]
        self.assertIn('superficie_id != "segunda_mano"', venta)
        self.assertIn('String(jornada.get("fase", "")) != "trayecto"', venta)
        self.assertIn("Inventario.CARRIED", self.comercio)
        self.assertIn("Inventario.vender(inventario, item_id)", venta)
        self.assertIn('jornada["dinero"] = int(jornada.get("dinero", 0)) + importe', venta)
        self.assertIn('"no_llevado"', venta)
        self.assertNotIn('jornada["acciones"]', venta)
        self.assertNotIn('jornada["cerrados_hoy"]', venta)

    def test_reventa_delega_bloqueo_onirico_en_inventario(self):
        venta = self.comercio.split("static func vender", 1)[1].split(
            "static func fuente_cultural", 1
        )[0]
        self.assertIn('String(venta.get("motivo", "reventa_rechazada"))', venta)
        self.assertNotIn('objeto.get("origen"', venta)

    def test_quiosco_compra_publicacion_sin_activar_sueno(self):
        self.assertIn('"semilla_onirica": "minotauro"', self.comercio)
        self.assertIn("static func fuente_cultural", self.comercio)
        self.assertNotIn("SemillasOniricas.activar_semilla_onirica", self.comercio)
        self.assertIn("interacción cultural deliberada", self.comercio)

    def test_compra_es_idempotente_y_persistente(self):
        self.assertIn('const CLAVE_COMPRAS := "comercio_barrio_compras"', self.comercio)
        self.assertIn("adquiridas.has(item_id)", self.comercio)
        self.assertIn('"ya_comprado": true', self.comercio)
        self.assertIn('"importe": 0', self.comercio)
        self.assertIn("jornada[CLAVE_COMPRAS] = adquiridas", self.comercio)

    def test_tabaco_es_consumo_repetible_sin_buff(self):
        self.assertIn('"id": "paquete_cigarrillos_98"', self.comercio)
        self.assertIn('"precio": 8', self.comercio)
        self.assertIn('"repetible": true', self.comercio)
        self.assertIn("if not repetible:", self.comercio)
        self.assertIn('"consumido": true', self.comercio)
        self.assertIn('"destino": "consumido"', self.comercio)
        cuerpo = self.comercio.split("if repetible:", 1)[1].split(
            "var objeto := _objeto_inventario", 1
        )[0]
        self.assertNotIn("Inventario.recoger", cuerpo)
        self.assertNotIn('jornada["acciones"]', cuerpo)
        self.assertNotIn('jornada["cerrados_hoy"]', cuerpo)

    def test_tabaco_y_reventa_funcionan_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_TABACO,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 28, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_documenta_limites_y_dependencias(self):
        for referencia in ("#61", "#83", "#93", "#96", "#97", "#442", "#676"):
            self.assertIn(referencia, self.doc)
        for limite in ("calle_identidad.gd", "casa_utileria.gd", "textos.csv"):
            self.assertIn(limite, self.doc)
        self.assertIn("comprar no activa", self.doc.lower())
        self.assertIn("reventa", self.doc.lower())
        self.assertIn("carried", self.doc)
        self.assertIn("onír", self.doc.lower())


if __name__ == "__main__":
    unittest.main()
