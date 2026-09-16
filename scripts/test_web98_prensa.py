import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "web98_prensa.json"
MODELO = ROOT / "godot" / "guion" / "web98_prensa.gd"
NAVEGADOR = ROOT / "godot" / "guion" / "navegador_siga.gd"
CABECERAS = ROOT / "godot" / "arte" / "os98" / "prensa_cabeceras_98.svg"


def cargar_catalogo() -> dict:
    return json.loads(CATALOGO.read_text(encoding="utf-8"))


class Web98PrensaTest(unittest.TestCase):
    def test_hay_cuatro_cabeceras_sin_rotulos_ideologicos_visibles(self) -> None:
        cabeceras = cargar_catalogo()["cabeceras"]
        self.assertEqual(len(cabeceras), 4)
        self.assertEqual({cabecera["fila_cabecera"] for cabecera in cabeceras}, {0, 1, 2, 3})
        self.assertEqual(len({cabecera["url"] for cabecera in cabeceras}), 4)

        rotulos_explicitos = ("comunista", "centrista", "socialdem", "neoliberal")
        for cabecera in cabeceras:
            visible = " ".join(
                [
                    cabecera["nombre"],
                    cabecera["lema"],
                    cabecera["snippet"],
                    *cabecera["prioridades"],
                ]
            ).lower()
            for rotulo in rotulos_explicitos:
                self.assertNotIn(rotulo, visible)

    def test_hecho_base_y_tratamiento_editorial_estan_separados(self) -> None:
        datos = cargar_catalogo()
        hechos = {hecho["id"]: hecho for hecho in datos["hechos"]}
        cabeceras = {cabecera["id"] for cabecera in datos["cabeceras"]}
        por_hecho: dict[str, list[dict]] = {}

        for tratamiento in datos["tratamientos"]:
            self.assertIn(tratamiento["hecho_id"], hechos)
            self.assertIn(tratamiento["cabecera_id"], cabeceras)
            hecho = hechos[tratamiento["hecho_id"]]
            ids_datos = {dato["id"] for dato in hecho["datos"]}
            self.assertLessEqual(set(tratamiento["datos_destacados"]), ids_datos)
            self.assertLessEqual(set(tratamiento["omisiones"]), ids_datos)
            self.assertTrue(tratamiento["titular"])
            self.assertTrue(tratamiento["entradilla"])
            self.assertIsInstance(tratamiento["enfasis"], list)
            por_hecho.setdefault(tratamiento["hecho_id"], []).append(tratamiento)

        self.assertGreaterEqual(len(hechos), 2)
        for hecho_id, tratamientos in por_hecho.items():
            self.assertEqual(
                {tratamiento["cabecera_id"] for tratamiento in tratamientos},
                cabeceras,
                hecho_id,
            )
            self.assertEqual(len({tratamiento["titular"] for tratamiento in tratamientos}), 4)

    def test_las_portadas_tienen_evolucion_temporal_declarativa(self) -> None:
        hechos = cargar_catalogo()["hechos"]
        self.assertTrue(any(hecho["disponible_hasta_dia"] == 1 for hecho in hechos))
        self.assertTrue(any(hecho["disponible_desde_dia"] == 2 for hecho in hechos))
        for hecho in hechos:
            self.assertGreaterEqual(hecho["jornada"], 1)
            self.assertGreaterEqual(hecho["disponible_desde_dia"], 1)

    def test_modelo_no_consulta_reloj_red_ni_procesos_reales(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn("class_name Web98Prensa", fuente)
        self.assertIn("func portada", fuente)
        self.assertIn("func tratamientos_de", fuente)
        for prohibido in (
            "Time.get_",
            "OS.get_datetime",
            "HTTPRequest",
            "HTTPClient",
            "TCPServer",
            "StreamPeerTCP",
            "WebSocketPeer",
            "OS.execute(",
            "OS.create_process(",
        ):
            self.assertNotIn(prohibido, fuente)

    def test_navegador_reutiliza_el_pack_visual_existente(self) -> None:
        self.assertTrue(CABECERAS.exists())
        fuente = NAVEGADOR.read_text(encoding="utf-8")
        self.assertIn('preload("res://arte/os98/prensa_cabeceras_98.svg")', fuente)
        self.assertIn("AtlasTexture.new()", fuente)
        self.assertIn("Web98Prensa.new()", fuente)


if __name__ == "__main__":
    unittest.main()
