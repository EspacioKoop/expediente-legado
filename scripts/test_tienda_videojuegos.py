from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
TIENDA = ROOT / "godot" / "guion" / "tienda_videojuegos.gd"
DOC = ROOT / "docs" / "tienda-videojuegos.md"


class TiendaVideojuegosTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tienda = TIENDA.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_catalogo_sale_del_indice_de_roms_propias(self):
        self.assertIn("RomsPropias.a_la_venta()", self.tienda)
        self.assertIn('"origen": "propia"', self.tienda)
        self.assertNotIn("const CATALOGO", self.tienda)

    def test_compra_solo_durante_trayecto(self):
        self.assertIn('jornada.get("fase", "")) != "trayecto"', self.tienda)
        self.assertIn('"fuera_del_trayecto"', self.tienda)

    def test_compra_gasta_dinero_sin_tocar_acciones(self):
        self.assertIn("Jornada.gastar(jornada, precio)", self.tienda)
        self.assertNotIn('jornada["acciones"]', self.tienda)
        self.assertNotIn('jornada["cerrados_hoy"]', self.tienda)

    def test_no_cobra_si_el_artefacto_no_existe(self):
        comprobacion = self.tienda.index("FileAccess.file_exists(ruta)")
        cobro = self.tienda.index("Jornada.gastar(jornada, precio)")
        self.assertLess(comprobacion, cobro)
        self.assertIn('"sin_stock"', self.tienda)

    def test_recomprar_es_idempotente(self):
        cuerpo_compra = self.tienda.split("static func comprar", 1)[1]
        ya_comprada = cuerpo_compra.index("adquiridas.has(id_rom)")
        cobro = cuerpo_compra.index("Jornada.gastar(jornada, precio)")
        self.assertLess(ya_comprada, cobro)
        self.assertIn('"ya_comprada": true', cuerpo_compra)
        self.assertIn('"importe": 0', cuerpo_compra)

    def test_persistencia_es_permanente_del_perfil(self):
        self.assertIn("PerfilRoms.migrar_desde_jornada(jornada)", self.tienda)
        self.assertIn("PerfilRoms.registrar(id_rom)", self.tienda)
        self.assertNotIn("jornada[CLAVE_COMPRAS] =", self.tienda)
        self.assertIn('jornada["dinero"] = int(jornada.get("dinero", 0)) + precio', self.tienda)

    def test_no_comercializa_roms_del_usuario_ni_descarga_contenido(self):
        catalogo = self.tienda.split("static func catalogo", 1)[1].split(
            "static func compras", 1
        )[0]
        self.assertNotIn('user://roms', catalogo)
        for termino in ("HTTPRequest", "HTTPClient", "download", "shell_open", "execute("):
            self.assertNotIn(termino, self.tienda)
        self.assertIn("ROMs comerciales", self.doc)
        self.assertIn("user://roms", self.doc)

    def test_documenta_el_corte_y_sus_dependencias(self):
        for referencia in ("#83", "#93", "#124", "#244", "#277", "#800"):
            self.assertIn(referencia, self.doc)
        self.assertIn("no modifica `espacios_catalogo.gd`", self.doc)
        self.assertIn("filtra el selector del emulador", self.doc)


if __name__ == "__main__":
    unittest.main()
