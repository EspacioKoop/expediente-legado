from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


RAIZ = Path(__file__).resolve().parents[1]
ARTE = RAIZ / "godot" / "arte" / "os98"
VISUAL = RAIZ / "godot" / "guion" / "escritorio_siga_visual.gd"
ADAPTADOR = RAIZ / "godot" / "guion" / "dia_escritorio_siga_app.gd"


class EscritorioSigaVisualTest(unittest.TestCase):
    def test_assets_svg_son_validos_y_tienen_las_medidas_previstas(self):
        esperados = {
            "wallpaper.svg": "0 0 1024 768",
            "system_mark.svg": "0 0 18 18",
            "iconos_32.svg": "0 0 192 32",
            "iconos_16.svg": "0 0 96 16",
            "iconos_programas_32.svg": "0 0 224 32",
            "iconos_programas_16.svg": "0 0 112 16",
            "cursores_32.svg": "0 0 192 32",
            "iconos_utilidades_32.svg": "0 0 256 32",
            "bandeja_16.svg": "0 0 80 16",
            "texturas_ui.svg": "0 0 640 128",
        }
        for nombre, view_box in esperados.items():
            ruta = ARTE / nombre
            self.assertTrue(ruta.is_file(), nombre)
            raiz = ET.fromstring(ruta.read_text(encoding="utf-8"))
            self.assertEqual(raiz.attrib.get("viewBox"), view_box, nombre)

    def test_atlas_conserva_las_seis_identidades_del_diseno(self):
        ids = ["siga", "equipo", "documentos", "red", "papelera", "ayuda"]
        for nombre in ("iconos_32.svg", "iconos_16.svg"):
            fuente = (ARTE / nombre).read_text(encoding="utf-8")
            for identidad in ids:
                self.assertIn(f'id="icon-{identidad}"', fuente, (nombre, identidad))

    def test_pack_extendido_conserva_identidades_del_asset_sheet(self):
        cursores = (ARTE / "cursores_32.svg").read_text(encoding="utf-8")
        for identidad in ("normal", "ayuda", "ocupado", "seleccionar", "texto", "no-disponible"):
            self.assertIn(f'id="cursor-{identidad}"', cursores)

        utilidades = (ARTE / "iconos_utilidades_32.svg").read_text(encoding="utf-8")
        for identidad in (
            "correo",
            "configuracion",
            "impresora",
            "notas",
            "calendario",
            "buscar",
            "ejecutar",
            "apagar",
        ):
            self.assertIn(f'id="util-{identidad}"', utilidades)

        bandeja = (ARTE / "bandeja_16.svg").read_text(encoding="utf-8")
        for identidad in ("volumen", "red", "correo", "sincronizando", "alertas"):
            self.assertIn(f'id="tray-{identidad}"', bandeja)

    def test_wallpaper_no_hornea_texto_ni_marcas_ajenas(self):
        fuente = (ARTE / "wallpaper.svg").read_text(encoding="utf-8").lower()
        self.assertNotIn("<text", fuente)
        self.assertNotIn("windows", fuente)
        self.assertNotIn("microsoft", fuente)

    def test_piel_visual_preload_y_recorta_los_atlas(self):
        fuente = VISUAL.read_text(encoding="utf-8")
        for ruta in (
            "res://arte/os98/wallpaper.svg",
            "res://arte/os98/system_mark.svg",
            "res://arte/os98/iconos_32.svg",
            "res://arte/os98/iconos_16.svg",
            "res://arte/os98/iconos_programas_32.svg",
            "res://arte/os98/iconos_programas_16.svg",
            "res://arte/os98/cursores_32.svg",
        ):
            self.assertIn(ruta, fuente)
        self.assertIn("extends EscritorioSiga", fuente)
        self.assertIn("AtlasTexture.new()", fuente)
        self.assertIn("STRETCH_KEEP_ASPECT_COVERED", fuente)
        self.assertIn("ORDEN_ICONOS", fuente)
        self.assertIn("ORDEN_ICONOS_PROGRAMAS", fuente)
        self.assertIn("ICONOS_PROGRAMAS_32 if tamano == 32 else ICONOS_PROGRAMAS_16", fuente)
        self.assertIn("ORDEN_CURSORES", fuente)

    def test_cursor_del_os98_se_instala_y_se_restaura_al_salir(self):
        fuente = VISUAL.read_text(encoding="utf-8")
        self.assertIn('Input.set_custom_mouse_cursor(_cursor("normal")', fuente)
        self.assertIn("Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)", fuente)
        self.assertIn('atlas.region = Rect2(float(indice * 32), 0.0, 32.0, 32.0)', fuente)

    def test_el_adaptador_asigna_solo_iconos_a_apps_reales(self):
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertIn("EscritorioSigaVisual.new()", fuente)
        self.assertIn('EscritorioSigaApp.new("siga-98", titulo_siga, creador_visor, "siga")', fuente)
        for identidad in (
            '"explorador", "Explorador", Callable(self, "_crear_explorador"), "explorador"',
            '"navegador-web98", "Navegador Web98", Callable(self, "_crear_navegador"), "web98"',
            '"software-98", "Archivo de programas", Callable(self, "_crear_software"), "software"',
            '"correo", CorreoSiga.texto("titulo_app"), Callable(self, "_crear_correo"), "correo"',
            '"bloc-notas", "Bloc de notas", Callable(self, "_crear_bloc_notas"), "bloc-notas"',
            '"calculadora", "Calculadora", Callable(self, "_crear_calculadora"), "calculadora"',
            '"catalogo-anomalias",',
        ):
            self.assertIn(identidad, fuente)
        self.assertIn('"catalogo-anomalias",\n\t\t)', fuente)
        self.assertIn('registrar_identidad_visual("ayuda-sistema", "ayuda")', fuente)
        for id_sin_app in ("equipo", "documentos", "red", "papelera"):
            self.assertNotIn(f'registrar_aplicacion("{id_sin_app}"', fuente)


if __name__ == "__main__":
    unittest.main()
