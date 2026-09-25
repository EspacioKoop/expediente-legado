"""Regresión estática y matemática de contraste del tema OS98 (#792)."""

from pathlib import Path
import re
import unittest

RAIZ = Path(__file__).resolve().parents[1]
ESTILO = RAIZ / "godot/guion/estilo_siga.gd"
FUENTE = ESTILO.read_text(encoding="utf-8")
MIN_AA = 4.5


def _constante(nombre):
    patron = rf'const {re.escape(nombre)} := Color\("([0-9a-fA-F]{{6}})"\)'
    coincidencia = re.search(patron, FUENTE)
    if not coincidencia:
        raise AssertionError(f"No se encontró el color {nombre}")
    valor = coincidencia.group(1)
    return tuple(int(valor[i : i + 2], 16) / 255.0 for i in (0, 2, 4))


def _lineal(canal):
    return canal / 12.92 if canal <= 0.04045 else ((canal + 0.055) / 1.055) ** 2.4


def _luminancia(rgb):
    r, g, b = rgb
    return 0.2126 * _lineal(r) + 0.7152 * _lineal(g) + 0.0722 * _lineal(b)


def contraste(a, b):
    la, lb = _luminancia(a), _luminancia(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


class ContrasteSigaTest(unittest.TestCase):
    def test_pares_del_tema_superan_wcag_aa(self):
        colores = {
            nombre: _constante(nombre)
            for nombre in (
                "PAPEL",
                "PAPEL_BOTON",
                "PAPEL_PULSADO",
                "PAPEL_ARCHIVADO",
                "NEGRO",
                "BLANCO",
                "AZUL_TITULO",
                "AZUL_ENLACE",
                "GRIS_TEXTO",
                "GRIS_TEXTO_DESHABILITADO",
            )
        }
        pares = {
            "texto general sobre papel": (colores["NEGRO"], colores["PAPEL"]),
            "botón sobre papel": (colores["NEGRO"], colores["PAPEL_BOTON"]),
            "botón pulsado": (colores["NEGRO"], colores["PAPEL_PULSADO"]),
            "expediente sellado": (colores["NEGRO"], colores["PAPEL_ARCHIVADO"]),
            "texto principal sobre blanco": (colores["NEGRO"], colores["BLANCO"]),
            "selección sobre azul": (colores["BLANCO"], colores["AZUL_TITULO"]),
            "enlace sobre blanco": (colores["AZUL_ENLACE"], colores["BLANCO"]),
            "texto secundario sobre blanco": (colores["GRIS_TEXTO"], colores["BLANCO"]),
            "readonly sobre papel": (colores["GRIS_TEXTO"], colores["PAPEL"]),
            "disabled sobre papel": (colores["GRIS_TEXTO_DESHABILITADO"], colores["PAPEL"]),
        }
        for nombre, (frente, fondo) in pares.items():
            with self.subTest(nombre=nombre):
                self.assertGreaterEqual(contraste(frente, fondo), MIN_AA)

    def test_ninguna_superficie_con_texto_es_gris(self):
        # Misma definición que ContrasteTexto.es_gris: casi sin croma, ni casi
        # blanco ni casi negro. El papel del OS98 es cálido a propósito.
        for nombre in ("PAPEL", "PAPEL_BOTON", "PAPEL_PULSADO", "PAPEL_ARCHIVADO"):
            with self.subTest(nombre=nombre):
                rgb = _constante(nombre)
                croma = max(rgb) - min(rgb)
                lum = _luminancia(rgb)
                self.assertFalse(croma < 0.05 and 0.03 < lum < 0.85)
        self.assertNotIn("caja_hundida(GRIS)", FUENTE)
        self.assertNotIn('Color("d0d0d0")', FUENTE)
        self.assertIn('tema.set_stylebox("panel", "PanelContainer", caja_saliente(PAPEL))', FUENTE)

    def test_controles_problematicos_usan_la_paleta_comun(self):
        contratos = (
            'tema.set_color("font_color", "Label", NEGRO)',
            'tema.set_color("default_color", "RichTextLabel", NEGRO)',
            'tema.set_stylebox("normal", "RichTextLabel", caja_hundida(BLANCO))',
            'tema.set_color("font_color", "ItemList", NEGRO)',
            'tema.set_color("font_hovered_color", "ItemList", NEGRO)',
            'tema.set_color("font_selected_color", "ItemList", BLANCO)',
            'tema.set_color("font_disabled_color", "ItemList", GRIS_TEXTO_DESHABILITADO)',
            'tema.set_stylebox("panel", "ItemList", caja_hundida(BLANCO))',
            'tema.set_color("font_placeholder_color", tipo, GRIS_TEXTO)',
            'tema.set_color("font_disabled_color", tipo, GRIS_TEXTO_DESHABILITADO)',
            "_configurar_texto_y_listas(tema)",
        )
        for contrato in contratos:
            with self.subTest(contrato=contrato):
                self.assertIn(contrato, FUENTE)

    def test_regresion_headless_calcula_el_ratio(self):
        prueba = (RAIZ / "godot/pruebas/pruebas_contraste_siga.gd").read_text(
            encoding="utf-8"
        )
        self.assertIn("const MIN_AA := 4.5", prueba)
        self.assertIn("func _contraste(a: Color, b: Color) -> float:", prueba)
        self.assertIn('tema.get_color("font_color", "ItemList")', prueba)
        self.assertIn('tema.get_color("default_color", "RichTextLabel")', prueba)


if __name__ == "__main__":
    unittest.main()
