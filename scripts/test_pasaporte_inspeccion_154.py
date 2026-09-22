import json
from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot/datos/puntos_inspeccion.json"
PASAPORTE = ROOT / "godot/guion/pasaporte_inspeccion.gd"
PUNTO_3D = ROOT / "godot/guion/punto_inspeccion_3d.gd"
PARTIDA = ROOT / "godot/guion/partida.gd"
PRUEBA_GODOT = ROOT / "godot/pruebas/pruebas_pasaporte_inspeccion_154.gd"


class PasaporteInspeccion154Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        cls.pasaporte = PASAPORTE.read_text(encoding="utf-8")
        cls.punto = PUNTO_3D.read_text(encoding="utf-8")
        cls.partida = PARTIDA.read_text(encoding="utf-8")
        cls.prueba_godot = PRUEBA_GODOT.read_text(encoding="utf-8")

    def test_catalogo_minimo_es_declarativo_y_un_punto_por_zona(self):
        self.assertEqual(len(self.catalogo), 4)
        self.assertEqual(
            {entrada["zona"] for entrada in self.catalogo},
            {"archivo", "trayecto", "casa", "sueño"},
        )
        ids = [entrada["id"] for entrada in self.catalogo]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(
            {entrada["modo_observacion"] for entrada in self.catalogo},
            {"examinar"},
        )
        permitidas = {"id", "zona", "ancla", "modo_observacion"}
        for entrada in self.catalogo:
            self.assertEqual(set(entrada), permitidas)
            self.assertTrue(entrada["id"].strip())
            self.assertTrue(entrada["ancla"].strip())

    def test_catalogo_no_inventa_recompensas_condiciones_ni_coordenadas(self):
        serializado = json.dumps(self.catalogo, ensure_ascii=False).lower()
        for prohibido in (
            "dinero",
            "accion",
            "pista",
            "recompensa",
            "lluvia",
            "reasignacion",
            "gato_ausente",
            "coordenad",
            "vector3",
        ):
            self.assertNotIn(prohibido, serializado)

    def test_registro_reutiliza_persistencia_sin_segundo_guardado(self):
        self.assertIn('const PREFIJO_SELLO := "inspeccion:"', self.pasaporte)
        self.assertIn("estado.get(Sellos.CLAVE_ESTADO, [])", self.pasaporte)
        self.assertIn("estado[Sellos.CLAVE_ESTADO] = obtenidos", self.pasaporte)
        self.assertIn('"ya-observado"', self.pasaporte)
        self.assertIn('"desconocido"', self.pasaporte)
        self.assertNotIn("FileAccess.open("user://", self.pasaporte)
        self.assertNotIn("Partida.", self.pasaporte)

    def test_punto_3d_solo_emite_observacion_deliberada(self):
        self.assertIn("extends Interactuable3D", self.punto)
        self.assertIn("signal observado(punto_id: String, actor: Node)", self.punto)
        self.assertIn("verbo = Verbo.EXAMINAR", self.punto)
        self.assertIn("activado.connect(_emitir_observacion)", self.punto)
        self.assertIn("observado.emit(_punto_id, actor)", self.punto)
        for prohibido in ("Input.", "Partida.", "guardar(", "dinero", "acciones", "pistas_descubiertas"):
            self.assertNotIn(prohibido, self.punto)

    def test_partida_ya_persiste_el_almacen_reutilizado(self):
        self.assertIn('"sellos_obtenidos": []', self.partida)
        validacion = self.partida.split("static func validar", 1)[1]
        self.assertIn('"sellos_obtenidos"', validacion)

    def test_regresion_cubre_interaccion_y_roundtrip_real(self):
        for token in (
            "punto.interactuar(null)",
            "partida.guardar(RUTA_PRUEBA)",
            "recargada.cargar(RUTA_PRUEBA)",
            "repetir después de recargar sigue siendo idempotente",
            "inspeccionar no concede dinero",
            "inspeccionar no concede acciones",
            "inspeccionar no concede pistas",
        ):
            self.assertIn(token, self.prueba_godot)

    def test_contrato_ejecutable_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_pasaporte_inspeccion_154.gd",
            "23 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
