from pathlib import Path
import csv
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "dia_salidas_confirmadas_app.gd"
ASCENSOR = ROOT / "godot" / "guion" / "dia_ascensor_app.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class SalidaOficinaConfirmada790Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.ascensor = ASCENSOR.read_text(encoding="utf-8")
        catalogo = CATALOGO.read_text(encoding="utf-8")
        inicio = catalogo.index("const OFICINA := {")
        fin = catalogo.index("\nconst CALLE := {", inicio)
        cls.oficina = catalogo[inicio:fin]
        with TEXTOS.open(encoding="utf-8", newline="") as archivo:
            cls.textos = {fila["clave"]: fila["es"] for fila in csv.DictReader(archivo)}

    def test_se_inserta_sin_duplicar_la_regla_de_jornada(self):
        self.assertIn(
            'extends "res://guion/dia_jornada_app.gd"',
            self.capa,
        )
        self.assertIn(
            'extends "res://guion/dia_salidas_confirmadas_app.gd"',
            self.ascensor,
        )
        for regla in ("Jornada.fichar_salida", "PronosticosAuditoria", "_guardar_o_avisar"):
            self.assertNotIn(regla, self.capa)

    def test_el_area_historica_deja_de_dispararse_por_proximidad(self):
        self.assertIn("salida.monitoring = false", self.capa)
        self.assertIn("salida.monitorable = false", self.capa)
        self.assertIn('String(area.get_meta("destino", "")) != "trayecto"', self.capa)

    def test_la_puerta_usa_el_contrato_comun_de_interaccion(self):
        self.assertIn("Interactuable3D.new()", self.capa)
        self.assertIn("Interactuable3D.Verbo.ABRIR", self.capa)
        self.assertIn('tr("SALIDA_PUERTA_OFICINA")', self.capa)
        self.assertIn("puerta.activado.connect(_pedir_confirmacion_salida)", self.capa)
        self.assertIn("caja.size = TAM_INTERACCION", self.capa)
        self.assertIn("DESPLAZAMIENTO_INTERACCION", self.capa)

    def test_acercarse_a_la_puerta_tambien_abre_la_misma_confirmacion(self):
        self.assertIn('NOMBRE_ZONA_ACCESO_OFICINA := "ZonaAccesoSalidaOficina"', self.capa)
        self.assertIn("caja.size = TAM_ACCESO", self.capa)
        self.assertIn("zona.body_entered.connect(_al_acercarse_a_salida)", self.capa)
        self.assertIn("_pedir_confirmacion_salida(cuerpo)", self.capa)

    def test_confirmar_reinyecta_el_transito_existente_y_cancelar_no(self):
        self.assertIn("ConfirmationDialog.new()", self.capa)
        self.assertIn("dialogo.confirmed.connect(_confirmar_salida_oficina)", self.capa)
        self.assertIn("dialogo.canceled.connect(_cancelar_salida_oficina)", self.capa)
        self.assertIn("dialogo.get_cancel_button().grab_focus.call_deferred()", self.capa)
        self.assertIn("_confirmacion_salida.hide()", self.capa)
        self.assertIn("_confirmacion_salida.exclusive = false", self.capa)
        confirmar = self.capa.split("func _confirmar_salida_oficina()", 1)[1].split(
            "func _cancelar_salida_oficina()", 1
        )[0]
        cancelar = self.capa.split("func _cancelar_salida_oficina()", 1)[1].split(
            "func _cerrar_confirmacion_salida()", 1
        )[0]
        self.assertIn("_al_pisar_salida(_caminante, salida)", confirmar)
        self.assertNotIn("_al_pisar_salida", cancelar)

    def test_la_puerta_fisica_y_el_trigger_siguen_en_el_mismo_punto_de_salida(self):
        self.assertIn('"rol": "puerta_archivo"', self.oficina)
        self.assertIn('"destino": "trayecto"', self.oficina)
        self.assertIn('"rotulo": "SALIDA_OFICINA"', self.oficina)
        self.assertIn('"visible": false', self.oficina)

    def test_textos_de_confirmacion_son_explicitos(self):
        self.assertEqual(self.textos["SALIDA_PUERTA_OFICINA"], "puerta de la oficina")
        self.assertEqual(self.textos["SALIDA_CONFIRMAR_TITULO"], "Confirmar salida")
        self.assertEqual(self.textos["SALIDA_CONFIRMAR_OFICINA"], "¿Salir de la oficina?")
        self.assertEqual(self.textos["SALIDA_CONFIRMAR_ACEPTAR"], "Salir")
        self.assertEqual(self.textos["SALIDA_CONFIRMAR_CANCELAR"], "Quedarse")


if __name__ == "__main__":
    unittest.main()
