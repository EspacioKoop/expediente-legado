"""Lo que las ROMs propias dibujan tiene que leerse (#805).

Caza Píxeles, RYU FLOW y Myrmidon llenaban el fondo de letras sueltas
(`!!!!TTTTXXXX`) porque su bucle de limpieza escribía el contador en vez de 0,
y pintaban texto y figuras en un gris casi blanco. Los tests de cada ROM miran
lógica y memoria, no la pantalla, así que nada lo detectó.

Lo que se ve de verdad se comprueba en CI con el mismo núcleo de la Portátil
Color 98: `godot/pruebas/roms_pantalla_smoke.gd`.
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
MINIJUEGOS = ROOT / "gbc" / "minijuegos"

# ROM, fuente y color de la paleta de fondo que hace de tinta.
TINTA = {
    "caza_pixeles_98": ("main.asm", 1),
    "ryu_flow_98": ("main.asm", 1),
    "aquiles_98": ("game.asm", 1),
}


def _fuentes():
    for carpeta in sorted(MINIJUEGOS.iterdir()):
        for nombre in ("main.asm", "game.asm"):
            fuente = carpeta / nombre
            if fuente.exists():
                yield fuente


def _luminancia(color555: int) -> float:
    canales = [((color555 >> desplazamiento) & 0x1F) / 31 for desplazamiento in (0, 5, 10)]
    lineal = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in canales]
    return 0.2126 * lineal[0] + 0.7152 * lineal[1] + 0.0722 * lineal[2]


def _contraste(a: int, b: int) -> float:
    claro, oscuro = sorted((_luminancia(a), _luminancia(b)), reverse=True)
    return (claro + 0.05) / (oscuro + 0.05)


class RomsPantallaTest(unittest.TestCase):
    def test_ci_mira_la_pantalla_con_el_nucleo_del_juego(self):
        ci = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
        self.assertIn("res://pruebas/roms_pantalla_smoke.gd", ci)

    def test_los_bucles_de_limpieza_escriben_cero_en_cada_celda(self):
        """`ld a, b / or c` pisa A: el valor hay que cargarlo dentro del bucle."""
        rotos = []
        for fuente in _fuentes():
            lineas = fuente.read_text(encoding="utf-8").splitlines()
            for indice, linea in enumerate(lineas):
                if linea.strip() != "ld [hli], a":
                    continue
                siguiente = [l.strip() for l in lineas[indice + 1 : indice + 5]]
                if not ({"ld a, b", "ld a, c"} & set(siguiente) and {"or b", "or c"} & set(siguiente)):
                    continue
                inicio = indice
                while inicio > 0 and not lineas[inicio].strip().endswith(":"):
                    inicio -= 1
                cuerpo = [l.strip() for l in lineas[inicio + 1 : indice]]
                if not any(re.match(r"(xor a|ld a,)", l) for l in cuerpo):
                    rotos.append(f"{fuente.relative_to(ROOT)}:{indice + 1}")
        self.assertEqual(rotos, [])

    def test_la_tinta_contrasta_con_el_fondo(self):
        for rom, (nombre, indice_tinta) in TINTA.items():
            texto = (MINIJUEGOS / rom / nombre).read_text(encoding="utf-8")
            bloque = texto.split("PaletaFondo:", 1)[1].split("PaletaFondoFin:", 1)[0]
            colores = [int(v, 16) for v in re.findall(r"\$([0-9A-Fa-f]{4})", bloque)]
            with self.subTest(rom=rom):
                self.assertGreaterEqual(_contraste(colores[0], colores[indice_tinta]), 4.5)
                self.assertIn("ld a, %11101100\n    ldh [rBGP], a", texto)


if __name__ == "__main__":
    unittest.main()
