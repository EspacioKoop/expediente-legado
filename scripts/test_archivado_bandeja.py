from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "archivado_bandeja.gd"


class ArchivadoBandejaTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_estado_y_superficie_son_puros(self):
        self.assertIn("class_name ArchivadoBandeja", self.source)
        self.assertIn("extends RefCounted", self.source)
        for funcion in (
            "nueva",
            "sincronizar",
            "colocar",
            "resultado",
            "cerrar",
            "abandonar",
            "siguiente_pendiente",
            "serializar",
            "restaurar",
        ):
            self.assertIn(f"static func {funcion}", self.source)
        self.assertNotIn("extends Node", self.source)
        self.assertNotIn("Partida", self.source)

    def test_reutiliza_la_regla_de_archivado(self):
        self.assertIn("Archivado.es_clasificable", self.source)
        self.assertIn("Archivado.evaluar", self.source)

    def test_error_no_elimina_la_carpeta_y_no_rearchiva_duplicados(self):
        self.assertIn("Una colocación incorrecta no destruye el caso", self.source)
        self.assertIn('estado["colocaciones"]', self.source)
        self.assertIn("append(colocacion)", self.source)
        self.assertIn('_contiene_id(estado.get("pendientes", []), caso_id)', self.source)

    def test_resultado_cuenta_las_carpetas_fisicamente_pendientes(self):
        self.assertIn(
            'resumen["pendientes"] = estado.get("pendientes", []).size()', self.source
        )
        self.assertIn('resumen["completada"]', self.source)

    def test_abandono_es_valido_y_reanudable(self):
        self.assertIn('estado["abandonada"] = true', self.source)
        bloque = self.source.split("static func abandonar", 1)[1].split(
            "static func siguiente_pendiente", 1
        )[0]
        self.assertNotIn('estado["cerrada"] = true', bloque)

    def test_guardado_solo_persiste_ids_y_decisiones(self):
        bloque = self.source.split("static func serializar", 1)[1].split(
            "static func restaurar", 1
        )[0]
        self.assertIn('"caso_id": caso_id', bloque)
        self.assertIn('"destino":', bloque)
        self.assertNotIn('"registros"', bloque)
        self.assertNotIn('"caso": caso', bloque)

    def test_recarga_rehidrata_desde_catalogo_y_sincroniza_nuevos_casos(self):
        bloque = self.source.split("static func restaurar", 1)[1]
        self.assertIn("_catalogo_por_id(catalogo)", bloque)
        self.assertIn("return sincronizar(estado, catalogo, folios_leidos)", bloque)


if __name__ == "__main__":
    unittest.main()
