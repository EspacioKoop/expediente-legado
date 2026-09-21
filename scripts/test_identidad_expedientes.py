from pathlib import Path
import json
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "identidad_expedientes.json"
VISOR = ROOT / "godot" / "guion" / "visor_identidad_app.gd"
ANEXOS = ROOT / "godot" / "guion" / "visor_anexos_app.gd"
METICULOSIDAD = ROOT / "godot" / "guion" / "visor_meticulosidad_app.gd"
PRONOSTICOS = ROOT / "godot" / "guion" / "visor_pronosticos_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "visor.tscn"


class IdentidadExpedientesTest(unittest.TestCase):
    def test_catalogo_y_assets_se_validan_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_identidad_expedientes.gd",
            "67 pasadas, 0 fallos",
        )

    def test_hay_diez_identidades_y_portadas_distintas(self):
        catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        self.assertEqual(len(catalogo), 10)
        self.assertEqual(len({ficha["icono"] for ficha in catalogo.values()}), 10)
        self.assertEqual(len({ficha["lamina"] for ficha in catalogo.values()}), 10)
        self.assertEqual(len({ficha["acento"] for ficha in catalogo.values()}), 10)
        for ficha in catalogo.values():
            self.assertTrue(ficha["codigo"])
            self.assertTrue(ficha["motivo"])
            self.assertTrue(ficha["icono"].startswith("res://arte/siga_expedientes/"))
            self.assertTrue(ficha["lamina"].startswith("res://arte/siga_expedientes/lamina_"))

    def test_los_dos_casos_del_gate_tienen_fichas_de_sujeto_no_biograficas(self):
        catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        sujetos = {
            caso_id: ficha["sujeto"]
            for caso_id, ficha in catalogo.items()
            if ficha.get("sujeto")
        }
        self.assertEqual(set(sujetos), {"caso@1", "caso2@2"})
        self.assertEqual(len(set(sujetos.values())), 2)
        for ruta in sujetos.values():
            self.assertTrue(ruta.startswith("res://arte/siga_expedientes/sujeto_"))
            asset = ROOT / "godot" / ruta.removeprefix("res://")
            texto = asset.read_text(encoding="utf-8")
            self.assertIn("silueta no biográfica", texto)
            self.assertNotIn("<text", texto)

    def test_la_identidad_es_presentacion_sin_reglas_de_juego(self):
        codigo = VISOR.read_text(encoding="utf-8")
        self.assertIn("extends RefCounted", codigo)
        self.assertIn("archivo.set_item_icon", codigo)
        self.assertIn("func actualizar(caso: Dictionary)", codigo)
        self.assertIn("func mostrar_portada(visible: bool)", codigo)
        self.assertIn('_textura_de(identidad, "sujeto")', codigo)
        self.assertIn("_portada_fila", codigo)
        self.assertNotIn("gastar_accion", codigo)
        self.assertNotIn("gastar_lectura", codigo)
        self.assertNotIn("Acusacion.acusar", codigo)

    def test_portada_cede_el_espacio_al_abrir_un_folio(self):
        anexos = ANEXOS.read_text(encoding="utf-8")
        meticulosidad = METICULOSIDAD.read_text(encoding="utf-8")
        escena = ESCENA.read_text(encoding="utf-8")
        pronosticos = PRONOSTICOS.read_text(encoding="utf-8")
        self.assertIn('extends "res://guion/visor_meticulosidad_app.gd"', anexos)
        self.assertIn('extends "res://guion/visor_metadatos_app.gd"', meticulosidad)
        self.assertIn('preload("res://guion/visor_identidad_app.gd")', anexos)
        self.assertIn("_identidad_expedientes.mostrar_portada(false)", anexos)
        self.assertIn("_identidad_expedientes.mostrar_portada(true)", anexos)
        self.assertIn('path="res://guion/visor_pronosticos_app.gd"', escena)
        self.assertIn('extends "res://guion/visor_anexos_app.gd"', pronosticos)


if __name__ == "__main__":
    unittest.main()
