import json
from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CATALOGO = RAIZ / "godot" / "datos" / "anomalias_sueno.json"
TEXTOS = RAIZ / "godot" / "datos" / "catalogo_anomalias_textos.json"
VISUALES = RAIZ / "godot" / "datos" / "catalogo_anomalias_visuales.json"
CONTRATO = RAIZ / "godot" / "guion" / "catalogo_anomalias.gd"
UI = RAIZ / "godot" / "guion" / "catalogo_anomalias_siga.gd"
UTILERIA = RAIZ / "godot" / "guion" / "sueno_utileria.gd"
PARTIDA = RAIZ / "godot" / "guion" / "partida.gd"
PROMETEO = RAIZ / "godot" / "guion" / "prometeo.gd"
CONTROLADOR = RAIZ / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
ESCRITORIO = RAIZ / "godot" / "guion" / "dia_escritorio_siga_app.gd"
PRUEBA_GODOT = RAIZ / "godot" / "pruebas" / "pruebas_catalogo_anomalias.gd"


class CatalogoAnomaliasTest(unittest.TestCase):
    def setUp(self):
        self.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))
        self.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        self.visuales = json.loads(VISUALES.read_text(encoding="utf-8"))
        self.codigo = CONTRATO.read_text(encoding="utf-8")
        self.ui = UI.read_text(encoding="utf-8")
        self.utileria = UTILERIA.read_text(encoding="utf-8")
        self.partida = PARTIDA.read_text(encoding="utf-8")
        self.prometeo = PROMETEO.read_text(encoding="utf-8")
        self.controlador = CONTROLADOR.read_text(encoding="utf-8")
        self.escritorio = ESCRITORIO.read_text(encoding="utf-8")
        self.prueba_godot = PRUEBA_GODOT.read_text(encoding="utf-8")

    def test_catalogo_declara_ids_estables_y_origen_real(self):
        ids = [entrada["id"] for entrada in self.catalogo]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertGreaterEqual(len(ids), 3)
        for entrada in self.catalogo:
            self.assertEqual(entrada["origen_tipo"], "objeto")
            self.assertIn(entrada["origen_id"], self.utileria)
            self.assertTrue(entrada["titulo"].strip())
            self.assertTrue(entrada["descripcion"].strip())
            self.assertTrue(entrada["nota_visual"].strip())
            representacion = entrada["representacion"]
            self.assertEqual(representacion["modelo"], entrada["origen_id"])
            self.assertIn(representacion["tipo"], {"modelo-procedural", "asset-cc0"})
            if representacion["tipo"] == "asset-cc0":
                self.assertTrue(representacion["modelo"].startswith("household_goods/"))

    def test_catalogo_no_contiene_ubicaciones_soluciones_ni_recompensas(self):
        permitidas = {
            "id",
            "titulo",
            "descripcion",
            "nota_visual",
            "origen_tipo",
            "origen_id",
            "representacion",
            "modo_observacion",
        }
        for entrada in self.catalogo:
            self.assertEqual(set(entrada), permitidas)
        serializado = json.dumps(self.catalogo, ensure_ascii=False).lower()
        for prohibido in ("coordenad", "ubicacion", "solucion", "dinero", "pista", "accion"):
            self.assertNotIn(prohibido, serializado)

    def test_recompensas_visuales_estan_separadas_y_autocontenidas(self):
        ids = {entrada["id"] for entrada in self.catalogo}
        self.assertEqual(set(self.visuales), ids | {"@vuelta-completa"})
        for clave, ficha in self.visuales.items():
            self.assertEqual(set(ficha), {"tipo", "ruta"})
            if clave == "@vuelta-completa":
                self.assertEqual(ficha["tipo"], "sello")
            else:
                self.assertEqual(ficha["tipo"], "boceto")
            ruta = ficha["ruta"]
            self.assertTrue(ruta.startswith("res://arte/catalogo_anomalias/"))
            self.assertTrue(ruta.endswith(".svg"))
            local = RAIZ / "godot" / ruta.removeprefix("res://")
            self.assertTrue(local.is_file(), ruta)
            svg = local.read_text(encoding="utf-8").lower()
            self.assertIn("<svg", svg)
            self.assertNotIn("<script", svg)
            self.assertNotRegex(svg, r'(?:href|xlink:href)=["\']https?://')

    def test_hay_anomalia_visible_por_exploracion(self):
        self.assertTrue(
            any(entrada["modo_observacion"] == "exploracion" for entrada in self.catalogo)
        )

    def test_api_separa_memoria_total_vuelta_y_variantes(self):
        self.assertIn('const CLAVE_TOTAL := "anomalias_descubiertas"', self.codigo)
        self.assertIn('const CLAVE_VUELTA := "anomalias_descubiertas_vuelta"', self.codigo)
        self.assertIn('const PREFIJO_VARIANTE := "@variante:"', self.codigo)
        self.assertIn("static func registrar(estado: Dictionary, anomalia_id: String)", self.codigo)
        self.assertIn("static func registrar_variante(", self.codigo)
        self.assertIn("static func variantes(estado: Dictionary, anomalia_id: String)", self.codigo)
        self.assertIn('"variante-registrada"', self.codigo)
        self.assertIn('"variante-conocida"', self.codigo)
        self.assertIn('"anomalia-no-registrada"', self.codigo)
        self.assertIn('"ya-reconocida"', self.codigo)
        self.assertIn('"reencontrada"', self.codigo)
        self.assertIn("static func reiniciar_vuelta(estado: Dictionary) -> void", self.codigo)
        self.assertIn("static func progreso(estado: Dictionary) -> Dictionary", self.codigo)
        self.assertIn("JSON.stringify([anomalia_id, folio])", self.codigo)

    def test_contrato_no_depende_de_partida_objetivos_ni_plataforma(self):
        for prohibido in ("Partida.", "Jornada.", "SuenoObjetivos", "GodotSteam", "Steam"):
            self.assertNotIn(prohibido, self.codigo)

    def test_partida_persiste_la_memoria_sin_ampliar_esquema(self):
        for clave in ("anomalias_descubiertas", "anomalias_descubiertas_vuelta"):
            self.assertIn(f'"{clave}": []', self.partida)
            self.assertIn(f'"{clave}"', self.partida.split("static func validar", 1)[1])
        self.assertIn("typeof(guardado[clave]) != TYPE_ARRAY", self.partida)
        self.assertNotIn('"anomalias_variantes"', self.partida)

    def test_reasignacion_borra_solo_la_memoria_de_vuelta(self):
        self.assertIn("CatalogoAnomalias.reiniciar_vuelta(estado)", self.prometeo)
        bloque = self.prometeo.split("static func reiniciar_vuelta", 1)[1]
        self.assertNotIn('estado["anomalias_descubiertas"] = []', bloque)

    def test_utileria_asocia_variantes_solo_a_folios_recibidos(self):
        self.assertIn("documentos_origen: Array = []", self.utileria)
        self.assertIn("var folios := _folios_validos(documentos_origen)", self.utileria)
        self.assertIn('anomalia.set_meta("documento_origen"', self.utileria)
        self.assertIn(
            "var indice := (i + desplazamiento) % prescripciones.size()", self.utileria
        )
        self.assertIn("folios[indice % folios.size()]", self.utileria)
        self.assertIn("static func _folios_validos(documentos_origen: Array)", self.utileria)
        self.assertNotIn("casos.json", self.utileria)
        self.assertNotIn("pistas_descubiertas", self.utileria)

    def test_observacion_3d_registra_base_variante_y_guarda_solo_si_hay_novedad(self):
        self.assertIn('dia.jornada.get("leido_hoy", [])', self.controlador)
        self.assertIn('get_meta("documento_origen", "")', self.controlador)
        self.assertIn("_al_observar_anomalia.bind(documento_origen)", self.controlador)
        self.assertIn("CatalogoAnomalias.registrar(partida_actual.estado, anomalia_id)", self.controlador)
        self.assertIn("CatalogoAnomalias.registrar_variante(", self.controlador)
        self.assertIn('["registrada", "reencontrada"]', self.controlador)
        self.assertIn('== "variante-registrada"', self.controlador)
        self.assertIn('dia._guardar_o_avisar("")', self.controlador)

        bloque = self.controlador.split("func _al_observar_anomalia", 1)[1]
        for prohibido in (
            'jornada["dinero"]',
            'jornada["acciones"]',
            'partida_actual.estado["vida"]',
            'partida_actual.estado["pistas_descubiertas"]',
            "SuenoObjetivos",
        ):
            self.assertNotIn(prohibido, bloque)

    def test_ui_muestra_variantes_y_recompensa_solo_en_entradas_conocidas(self):
        self.assertIn("class_name CatalogoAnomaliasSiga", self.ui)
        self.assertIn("CatalogoAnomalias.progreso(_estado)", self.ui)
        self.assertIn("CatalogoAnomalias.conocida(_estado, id)", self.ui)
        self.assertIn("CatalogoAnomalias.conocida_en_vuelta(_estado, id)", self.ui)
        self.assertIn("CatalogoAnomalias.variantes(_estado, id)", self.ui)
        self.assertIn('_t("variantes_documentales")', self.ui)
        self.assertIn('_t("variantes_folios")', self.ui)
        self.assertIn('_t("variantes_ninguna")', self.ui)
        self.assertIn('_t("entrada_bloqueada")', self.ui)
        self.assertIn('_t("entrada_vuelta_completa")', self.ui)
        self.assertIn(
            'const RUTA_VISUALES := "res://datos/catalogo_anomalias_visuales.json"', self.ui
        )
        self.assertIn("TextureRect.new()", self.ui)
        self.assertIn("_mostrar_recompensa(id)", self.ui)
        self.assertIn('_mostrar_recompensa("@vuelta-completa")', self.ui)
        self.assertIn("ResourceLoader.exists(ruta)", self.ui)
        self.assertIn("_texturas_visuales[ruta] = load(ruta)", self.ui)
        self.assertNotIn('get("origen_id"', self.ui)
        self.assertNotIn('get("modo_observacion"', self.ui)
        bloque_bloqueada = self.ui.split("func _mostrar_bloqueada", 1)[1].split(
            "func _mostrar_vuelta_completa", 1
        )[0]
        self.assertIn("_ocultar_recompensa()", bloque_bloqueada)
        self.assertNotIn("_mostrar_recompensa", bloque_bloqueada)
        for prohibido in ("SuenoObjetivos", 'jornada["dinero"]', 'jornada["acciones"]'):
            self.assertNotIn(prohibido, self.ui)

    def test_catalogo_tiene_identidad_visual_propia_sin_romper_el_shell(self):
        for token in (
            'const COLOR_INDICE := Color("1f2b2d")',
            'const COLOR_FICHA := Color("e7eadf")',
            'const COLOR_PAPEL := Color("f7f6ed")',
            'PanelContainer.new()',
            'panel_indice.name = "PanelIndice"',
            'panel_ficha.name = "PanelFicha"',
            'EstiloSiga.fuente_titulo()',
            'EstiloSiga.fuente_mono()',
            'EstiloSiga.fuente_documento()',
            '_caja_catalogo(COLOR_INDICE, COLOR_INDICE_BORDE, 10.0)',
            '_caja_catalogo(COLOR_FICHA, COLOR_INDICE_BORDE, 12.0)',
            '_caja_catalogo(COLOR_PAPEL, Color("a6ad9d"), 10.0)',
            'marca.text = _t("titulo_app")',
        ):
            self.assertIn(token, self.ui)

        # La personalidad vive dentro de la app: el marco de ventana común sigue
        # siendo propiedad del shell, no del Catálogo.
        for prohibido in ("Window.new()", "EscritorioSigaVisual", "registrar_aplicacion("):
            self.assertNotIn(prohibido, self.ui)

    def test_ui_externaliza_los_textos_fijos(self):
        claves = {
            "titulo_app",
            "titulo_indice",
            "leyenda",
            "progreso",
            "entrada_bloqueada",
            "entrada_vuelta_completa",
            "origen_material",
            "representacion_archivada",
            "variantes_documentales",
            "variantes_folios",
            "variantes_ninguna",
            "titulo_bloqueada",
            "origen_vacio",
            "descripcion_bloqueada",
            "representacion_vacia",
            "titulo_vuelta_completa",
            "origen_vuelta_completa",
            "descripcion_vuelta_completa",
            "representacion_vuelta_completa",
            "titulo_espera",
            "descripcion_espera",
            "titulo_fallback",
            "origen_fallback",
            "descripcion_fallback",
            "representacion_fallback",
        }
        self.assertEqual(set(self.textos), claves)
        self.assertTrue(all(isinstance(valor, str) and valor.strip() for valor in self.textos.values()))
        self.assertIn('const RUTA_TEXTOS := "res://datos/catalogo_anomalias_textos.json"', self.ui)
        self.assertIn("static func texto(clave: String) -> String", self.ui)
        literal_ui = re.compile(r'\.text\s*=\s*"[^\"]*[a-zá-úA-ZÁ-Ú]')
        self.assertIsNone(literal_ui.search(self.ui))

    def test_escritorio_registra_catalogo_como_app_sin_estado_paralelo(self):
        self.assertIn('"catalogo-anomalias"', self.escritorio)
        self.assertIn('CatalogoAnomaliasSiga.texto("titulo_app")', self.escritorio)
        self.assertIn('Callable(self, "_crear_catalogo_anomalias")', self.escritorio)
        self.assertIn("CatalogoAnomaliasSiga.new()", self.escritorio)
        self.assertIn("catalogo.configurar_estado(partida_actual.estado)", self.escritorio)
        bloque = self.escritorio.split("func _crear_catalogo_anomalias", 1)[1].split(
            "func _registrar_correo_leido", 1
        )[0]
        self.assertNotIn("guardar", bloque.lower())
        self.assertNotIn("registrar(", bloque)

    def test_hay_regresion_ejecutable_en_godot(self):
        self.assertIn("extends SceneTree", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.registrar", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.registrar_variante", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.variantes", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.reiniciar_vuelta", self.prueba_godot)
        self.assertIn("CatalogoAnomalias.progreso", self.prueba_godot)
        self.assertIn("Partida.new()", self.prueba_godot)
        self.assertIn("partida.guardar(ruta)", self.prueba_godot)
        self.assertIn("recargada.cargar(ruta)", self.prueba_godot)
        self.assertIn("Prometeo.reiniciar_vuelta", self.prueba_godot)
        self.assertIn("FOLIO-PERSISTENTE", self.prueba_godot)


if __name__ == "__main__":
    unittest.main()
