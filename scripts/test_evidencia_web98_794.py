from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
NAVEGADOR = ROOT / "godot" / "guion" / "navegador_siga.gd"
CAPTURA = ROOT / "godot" / "pruebas" / "capturar_web98_794.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "evidencia-web98-794.yml"


class EvidenciaWeb98794Test(unittest.TestCase):
    def test_navegador_consume_el_pack_visual_existente(self) -> None:
        fuente = NAVEGADOR.read_text(encoding="utf-8")
        for asset in (
            "web_cabeceras_sitios_98.svg",
            "web_navegacion_sitios_98.svg",
            "web_modulos_sitios_98.svg",
            "web_badges_88x31.svg",
            "web_decoracion_sitios_98.svg",
        ):
            self.assertIn(asset, fuente)
        self.assertIn("AtlasTexture.new()", fuente)
        self.assertIn("SITIOS_WEB_VISUALES", fuente)

    def test_captura_cubre_pagina_busqueda_y_pagina_personal(self) -> None:
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn('navegar("http://byte.local/")', fuente)
        self.assertIn('_mostrar_busqueda("coño")', fuente)
        self.assertIn('navegar("http://usuarios.red98/~becario/")', fuente)
        self.assertIn("root.get_texture().get_image()", fuente)

    def test_workflow_publica_las_tres_capturas_para_revision_humana(self) -> None:
        fuente = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("xvfb-run -a godot4", fuente)
        self.assertIn("capturar_web98_794.gd", fuente)
        self.assertIn("actions/upload-artifact@v4", fuente)
        self.assertIn("evidencia-web98-794-${{ github.sha }}", fuente)
        for nombre in (
            "byte-local",
            "busqueda-sin-falso-positivo",
            "pagina-personal",
        ):
            self.assertIn(nombre, fuente)


if __name__ == "__main__":
    unittest.main()
