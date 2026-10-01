import ast
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SONIDO_GD = ROOT / "godot" / "guion" / "sonido.gd"
MUSICA_GD = ROOT / "godot" / "guion" / "musica.gd"


def parsear_diccionario_gdscript(texto: str, nombre_constante: str) -> dict:
    patron = rf"const\s+{nombre_constante}\s*(?::=|=)\s*(\{{)"
    coincidencia = re.search(patron, texto)
    if not coincidencia:
        raise ValueError(f"No se encontró la constante {nombre_constante} en el guion GDScript.")
    inicio_idx = coincidencia.start(1)
    profundidad = 0
    en_cadena = False
    caracter_cadena = None
    fin_idx = None
    for i in range(inicio_idx, len(texto)):
        c = texto[i]
        if en_cadena:
            if c == caracter_cadena and texto[i - 1] != "\\":
                en_cadena = False
        else:
            if c in ('"', "'"):
                en_cadena = True
                caracter_cadena = c
            elif c == "{":
                profundidad += 1
            elif c == "}":
                profundidad -= 1
                if profundidad == 0:
                    fin_idx = i + 1
                    break
    if fin_idx is None:
        raise ValueError(f"No se pudo cerrar la llave del bloque {nombre_constante}.")

    bloque = texto[inicio_idx:fin_idx]
    lineas_limpias = []
    for linea in bloque.splitlines():
        linea_limpia = []
        en_str = False
        c_str = None
        for idx, char in enumerate(linea):
            if en_str:
                if char == c_str and linea[idx - 1] != "\\":
                    en_str = False
                linea_limpia.append(char)
            else:
                if char in ('"', "'"):
                    en_str = True
                    c_str = char
                    linea_limpia.append(char)
                elif char == "#":
                    break
                else:
                    linea_limpia.append(char)
        lineas_limpias.append("".join(linea_limpia))

    bloque_limpio = "\n".join(lineas_limpias)
    return ast.literal_eval(bloque_limpio)


class TestAudioChip1926(unittest.TestCase):
    def test_sin_ruta_historica_kenney_sfx(self):
        sonido_contenido = SONIDO_GD.read_text(encoding="utf-8")
        musica_contenido = MUSICA_GD.read_text(encoding="utf-8")

        self.assertNotIn(
            "kenney_sfx/",
            sonido_contenido,
            "se detectó la ruta obsoleta 'kenney_sfx/' en sonido.gd",
        )
        self.assertNotIn(
            "kenney_sfx/",
            musica_contenido,
            "se detectó la ruta obsoleta 'kenney_sfx/' en musica.gd",
        )

    def test_familias_abrir_y_cerrar_usan_rutas_chip(self):
        sonido_contenido = SONIDO_GD.read_text(encoding="utf-8")
        familias = parsear_diccionario_gdscript(sonido_contenido, "FAMILIAS")

        self.assertIn("abrir", familias)
        self.assertIn("cerrar", familias)

        rutas_abrir = familias["abrir"]
        rutas_cerrar = familias["cerrar"]

        esperado_abrir = [
            "chip/archivador_abrir_01.ogg",
            "chip/archivador_abrir_02.ogg",
            "chip/archivador_abrir_03.ogg",
        ]
        esperado_cerrar = [
            "chip/archivador_cerrar_01.ogg",
            "chip/archivador_cerrar_02.ogg",
            "chip/archivador_cerrar_03.ogg",
        ]

        self.assertEqual(
            rutas_abrir,
            esperado_abrir,
            f"FAMILIAS['abrir'] debe contener exactamente {esperado_abrir}",
        )
        self.assertEqual(
            rutas_cerrar,
            esperado_cerrar,
            f"FAMILIAS['cerrar'] debe contener exactamente {esperado_cerrar}",
        )

    def test_familias_respaldo_mantiene_fallback_auditado(self):
        sonido_contenido = SONIDO_GD.read_text(encoding="utf-8")
        familias_respaldo = parsear_diccionario_gdscript(
            sonido_contenido, "FAMILIAS_RESPALDO"
        )

        self.assertIn("abrir", familias_respaldo)
        self.assertIn("cerrar", familias_respaldo)
        self.assertTrue(
            len(familias_respaldo["abrir"]) > 0,
            "FAMILIAS_RESPALDO['abrir'] debe contener al menos un elemento de respaldo",
        )
        self.assertTrue(
            len(familias_respaldo["cerrar"]) > 0,
            "FAMILIAS_RESPALDO['cerrar'] debe contener al menos un elemento de respaldo",
        )


if __name__ == "__main__":
    unittest.main()
