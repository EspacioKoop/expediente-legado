from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CINEMATICA = RAIZ / "godot" / "guion" / "inicio_jornada_cinematica.gd"
CAPA = RAIZ / "godot" / "guion" / "dia_jornada_app.gd"


class InicioJornadaTest(unittest.TestCase):
    def setUp(self):
        self.cinematica = CINEMATICA.read_text(encoding="utf-8")
        self.capa = CAPA.read_text(encoding="utf-8")

    def test_primera_presentacion_dura_menos_de_tres_segundos(self):
        segundos = [float(valor) for valor in re.findall(r'"segundos":\s*([0-9.]+)', self.cinematica)]
        self.assertTrue(segundos)
        self.assertLess(sum(segundos), 3.0)

    def test_la_vista_sale_de_la_jornada_real(self):
        for campo in ("dia", "dinero", "acciones", "gato"):
            self.assertIn(f'"{campo}"', self.cinematica)
        self.assertIn("marca_de(jornada", self.cinematica)
        self.assertIn('"vuelta"', self.cinematica)

    def test_la_capa_no_avanza_el_calendario(self):
        prohibidas = (
            "Jornada.despertar(",
            "Jornada.despertar_de_golpe(",
            "Jornada.dormir(",
            "Jornada.fichar_salida(",
        )
        for llamada in prohibidas:
            self.assertNotIn(llamada, self.capa)

    def test_la_marca_se_guarda_antes_de_reproducir(self):
        marca = self.capa.index("partida.estado[CLAVE_ULTIMO_INICIO] = marca")
        guardar = self.capa.index('if not _guardar_o_avisar(""):', marca)
        reproducir = self.capa.index("_inicio_jornada.reproducir(", guardar)
        self.assertLess(marca, guardar)
        self.assertLess(guardar, reproducir)

    def test_solo_se_abre_al_comienzo_de_jornada(self):
        self.assertIn('jornada.get("fase", "") != "archivo"', self.capa)
        self.assertIn("Jornada.ACCIONES_POR_DIA", self.capa)
        self.assertIn("CLAVE_ULTIMO_INICIO", self.capa)


if __name__ == "__main__":
    unittest.main()
