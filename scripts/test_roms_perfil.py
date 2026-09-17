from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
PERFIL = ROOT / "godot" / "guion" / "perfil_roms.gd"
TIENDA = ROOT / "godot" / "guion" / "tienda_videojuegos.gd"
CONSOLA = ROOT / "godot" / "guion" / "consola_portatil_98.gd"
INICIO = ROOT / "godot" / "guion" / "inicio_app.gd"


class RomsPerfilTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.perfil = PERFIL.read_text(encoding="utf-8")
        cls.tienda = TIENDA.read_text(encoding="utf-8")
        cls.consola = CONSOLA.read_text(encoding="utf-8")
        cls.inicio = INICIO.read_text(encoding="utf-8")

    def test_biblioteca_vive_fuera_de_partida_y_jornada(self):
        self.assertIn('const RUTA := "user://perfil_roms.json"', self.perfil)
        self.assertIn('const CLAVE_COMPRAS := "roms_compradas"', self.perfil)
        self.assertIn("PerfilRoms.registrar(id_rom)", self.tienda)
        self.assertNotIn("jornada[CLAVE_COMPRAS] =", self.tienda)

    def test_migra_compras_de_guardados_anteriores_sin_cargar_partida(self):
        self.assertIn("static func migrar_desde_partida", self.perfil)
        self.assertIn('crudo.get("jornada", {})', self.perfil)
        self.assertIn("PerfilRoms.migrar_desde_partida(ruta)", self.inicio)
        self.assertNotIn("partida.cargar(ruta)\n\tPerfilRoms", self.inicio)

    def test_portatil_fisica_usa_la_biblioteca_permanente(self):
        self.assertIn("_app.roms_compradas = _roms_compradas()", self.consola)
        self.assertIn("return TiendaVideojuegos.compras({})", self.consola)
        self.assertNotIn("_compradas_en_jornada", self.consola)

    def test_inicio_abre_el_mismo_emulador_con_compras(self):
        self.assertIn('"Portátil Color 98"', self.inicio)
        self.assertIn("EmuladorPortatilAudioApp.new()", self.inicio)
        self.assertIn("app.roms_compradas = TiendaVideojuegos.compras({})", self.inicio)
        self.assertIn("CatalogoRomsUsuario.asegurar_carpeta()", self.inicio)

    def test_escritura_de_perfil_es_atomica(self):
        self.assertIn('var temporal := ruta + ".nuevo"', self.perfil)
        self.assertIn("DirAccess.rename_absolute", self.perfil)


if __name__ == "__main__":
    unittest.main()
