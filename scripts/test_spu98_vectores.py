"""Vectores manuales del perfil offline; no certifican una SPU completa."""
import importlib.util
import json
from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "laboratorio_sonoro_1475", RAIZ / "scripts/laboratorio_sonoro_1475.py"
)
LAB = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LAB)
VECTORES = json.loads(
    (RAIZ / "referencia/audio/chips/spu98_vectores.json").read_text(encoding="utf-8")
)


class SpuVectoresTest(unittest.TestCase):
    def test_pcm_contra_tramos_manuales_independientes(self):
        """Sin encoder ni segundo decoder para fabricar los esperados."""
        for caso in VECTORES["adpcm"]:
            with self.subTest(vector=caso["id"]):
                bloques = [bytes.fromhex(b) for b in caso["bloques_hex"]]
                self.assertTrue(bloques)
                self.assertTrue(all(len(b) == 16 for b in bloques))
                salida = LAB.decodificar_adpcm(b"".join(bloques))
                self.assertEqual(len(salida), len(bloques) * 28)
                self.assertTrue(caso["tramos"])
                for tramo in caso["tramos"]:
                    inicio, esperado = tramo["desde"], tramo["pcm"]
                    self.assertGreaterEqual(inicio, 0)
                    self.assertTrue(esperado)
                    self.assertLessEqual(inicio + len(esperado), len(salida))
                    self.assertEqual(salida[inicio:inicio + len(esperado)], esperado)

    def test_historia_es_del_flujo_y_no_se_reinicia_por_bloque(self):
        caso = next(c for c in VECTORES["adpcm"] if c["id"] == "ADPCM-04")
        previo, siguiente = map(bytes.fromhex, caso["bloques_hex"])
        self.assertEqual(LAB.decodificar_adpcm(previo + siguiente)[28:30], [167, 248])
        # Una llamada nueva sí empieza en cero: no equivale al flujo concatenado.
        self.assertEqual(LAB.decodificar_adpcm(siguiente), [0] * 28)

    def test_flags_no_controlan_el_decoder_offline(self):
        for flags in range(8):
            with self.subTest(flags=flags):
                primero = bytes([0x0C, flags] + [0x11] * 14)
                segundo = bytes([0x0C, 0] + [0x22] * 14)
                self.assertEqual(
                    LAB.decodificar_adpcm(primero + segundo), [1] * 28 + [2] * 28
                )

    def test_flags_del_encoder_y_relleno_no_equivalen_a_playback(self):
        for cantidad, bucle, esperados in (
            (1, False, [1]), (28, False, [1]), (29, False, [0, 1]),
            (1, True, [7]), (28, True, [7]), (29, True, [4, 3]),
        ):
            with self.subTest(cantidad=cantidad, bucle=bucle):
                datos = LAB.codificar_adpcm([1] * cantidad, bucle=bucle)
                self.assertEqual(list(datos[1::16]), esperados)
                self.assertEqual(len(datos), len(esperados) * 16)
                salida = LAB.decodificar_adpcm(datos)
                self.assertEqual(salida, [1] * cantidad + [0] * (-cantidad % 28))

    def test_cabeceras_fuera_del_perfil_se_rechazan(self):
        invalidas = [filtro << 4 for filtro in range(5, 16)]
        invalidas += [(filtro << 4) | shift for filtro in range(5) for shift in (13, 14, 15)]
        for cabecera in invalidas:
            with self.subTest(cabecera=cabecera), self.assertRaises(ValueError):
                LAB.decodificar_adpcm(bytes([cabecera] + [0] * 15))


if __name__ == "__main__":
    unittest.main()
