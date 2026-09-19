from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
VISOR_SELLO = ROOT / "godot" / "guion" / "visor_sello_app.gd"
ACUSACION = ROOT / "godot" / "guion" / "acusacion.gd"
PROMETEO = ROOT / "godot" / "guion" / "prometeo.gd"
CAPTURAR = ROOT / "godot" / "pruebas" / "capturar.gd"


class TarotProgresion1029Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.visor_sello = VISOR_SELLO.read_text(encoding="utf-8")
        cls.acusacion = ACUSACION.read_text(encoding="utf-8")
        cls.prometeo = PROMETEO.read_text(encoding="utf-8")
        cls.capturar = CAPTURAR.read_text(encoding="utf-8")

    def test_primera_pista_sincroniza_antes_del_guardado(self) -> None:
        inicio = self.visor.index('\t\t"pista":')
        fin = self.visor.index('\t\t"carta":', inicio)
        bloque = self.visor[inicio:fin]
        self.assertLess(bloque.index("descubiertas.append"), bloque.index("_sincronizar_tarot_por_pista()"))
        self.assertLess(bloque.index("_sincronizar_tarot_por_pista()"), bloque.index("_guardar_o_avisar()"))

    def test_pistas_delegan_en_regla_pura_sin_historia_oculta(self) -> None:
        inicio = self.visor.index("func _sincronizar_tarot_por_pista()")
        fin = self.visor.index("## Encontrar una carta escondida", inicio)
        bloque = self.visor[inicio:fin]
        self.assertIn("Prometeo.sincronizar_tarot_por_pistas(partida.estado)", bloque)
        self.assertRegex(
            bloque,
            re.compile(
                r"sincronizar_tarot_por_caso_resuelto\s*\(\s*"
                r"partida\.estado\s*,\s*caso\s*\)"
            ),
        )
        self.assertIn("_al_carta_desbloqueada(carta_id)", bloque)
        self.assertNotIn("cartas_conocidas", bloque)
        self.assertNotIn("_al_encontrar_carta", bloque)
        self.assertNotIn("_abrir_historia", bloque)

    def test_regla_por_pistas_cubre_mago_y_estrella_idempotentes(self) -> None:
        inicio = self.prometeo.index("static func sincronizar_tarot_por_pistas(")
        fin = self.prometeo.index("## Progreso por expediente", inicio)
        bloque = self.prometeo[inicio:fin]
        self.assertIn('pistas.size() >= 1', bloque)
        self.assertIn('desbloquear_carta_en_estado(estado, "el-mago")', bloque)
        self.assertIn('pistas.size() >= 20', bloque)
        self.assertIn('desbloquear_carta_en_estado(estado, "la-estrella")', bloque)
        self.assertEqual(bloque.count('nuevas.append("el-mago")'), 1)
        self.assertEqual(bloque.count('nuevas.append("la-estrella")'), 1)

    def test_caso_resuelto_delega_en_progreso_y_desbloquea_enamorados(self) -> None:
        inicio = self.prometeo.index(
            "static func sincronizar_tarot_por_caso_resuelto("
        )
        fin = self.prometeo.index("## Una acusación es precipitada", inicio)
        bloque = self.prometeo[inicio:fin]
        self.assertIn("Progreso.caso_resuelto(caso, pistas)", bloque)
        self.assertIn(
            'desbloquear_carta_en_estado(estado, "los-enamorados")',
            bloque,
        )
        self.assertIn('nuevas.append("los-enamorados")', bloque)
        self.assertEqual(bloque.count("return nuevas"), 1)

    def test_mundo_excluye_templanza_y_exige_archivo_completo(self) -> None:
        inicio = self.prometeo.index("static func sincronizar_tarot_mundo(")
        fin = self.prometeo.index("## Una acusación es precipitada", inicio)
        bloque = self.prometeo[inicio:fin]
        self.assertIn('["el-mundo", "la-templanza"]', bloque)
        self.assertIn('carta.get("recogida", false)', bloque)
        self.assertIn('carta.get("gastada", false)', bloque)
        self.assertIn(
            "Progreso.todos_resueltos(casos_principales, pistas)",
            bloque,
        )
        self.assertIn(
            'desbloquear_carta_en_estado(estado, "el-mundo")',
            bloque,
        )
        self.assertNotIn("cartas_conocidas", bloque)

    def test_mundo_se_evalua_solo_tras_eventos_reales(self) -> None:
        ready_inicio = self.visor.index("func _ready()")
        ready_fin = self.visor.index("func _draw()", ready_inicio)
        ready = self.visor[ready_inicio:ready_fin]
        self.assertNotIn("sincronizar_tarot_mundo", ready)

        pistas_inicio = self.visor.index("func _sincronizar_tarot_por_pista()")
        pistas_fin = self.visor.index("## Encontrar una carta escondida", pistas_inicio)
        pistas = self.visor[pistas_inicio:pistas_fin]
        self.assertIn("sincronizar_tarot_mundo", pistas)

        oculta_inicio = self.visor.index("func _al_encontrar_carta(")
        oculta_fin = self.visor.index("## Propaga únicamente", oculta_inicio)
        oculta = self.visor[oculta_inicio:oculta_fin]
        self.assertIn("sincronizar_tarot_mundo", oculta)
        self.assertLess(
            oculta.index("desbloquear_carta_en_estado"),
            oculta.index("sincronizar_tarot_mundo"),
        )
        self.assertLess(
            oculta.index("sincronizar_tarot_mundo"),
            oculta.index("_guardar_o_avisar()"),
        )

        eventos_inicio = self.visor.index("func _notificar_cartas_desbloqueadas(")
        eventos_fin = self.visor.index("## Hook de dominio", eventos_inicio)
        eventos = self.visor[eventos_inicio:eventos_fin]
        self.assertIn("if nuevas.is_empty()", eventos)
        self.assertIn("sincronizar_tarot_mundo", eventos)

    def test_veredicto_real_emite_hierofante_en_el_evento(self) -> None:
        inicio = self.acusacion.index("static func acusar(")
        fin = self.acusacion.index("## Quita vidas", inicio)
        bloque = self.acusacion[inicio:fin]
        self.assertLess(
            bloque.index('estado["veredictos"] = veredictos'),
            bloque.index(
                'Prometeo.desbloquear_carta_en_estado(estado, "el-hierofante")'
            ),
        )
        self.assertIn('cartas_desbloqueadas.append("el-hierofante")', bloque)
        self.assertIn('"cartas_desbloqueadas": cartas_desbloqueadas', bloque)

    def test_perder_vida_emite_ermitanio_desde_la_frontera_comun(self) -> None:
        inicio = self.acusacion.index("static func perder_vida(")
        fin = self.acusacion.index("## Cierra el careo", inicio)
        bloque = self.acusacion[inicio:fin]
        self.assertIn("vida_anterior", bloque)
        self.assertIn('estado["vida"] < vida_anterior', bloque)
        self.assertIn('estado["perdio_vida_en_esta_vuelta"] = true', bloque)
        self.assertIn(
            'Prometeo.desbloquear_carta_en_estado(estado, "el-ermitanio")',
            bloque,
        )
        self.assertIn('cartas_desbloqueadas.append("el-ermitanio")', bloque)
        self.assertLess(
            bloque.index(
                'Prometeo.desbloquear_carta_en_estado(estado, "el-ermitanio")'
            ),
            bloque.index("Prometeo.reiniciar_vuelta"),
        )
        self.assertIn(
            '"cartas_desbloqueadas": cartas_desbloqueadas',
            bloque,
        )
        self.assertRegex(
            bloque,
            re.compile(
                r'return\s*\{\s*"despido"\s*:\s*true\s*,\s*'
                r'"vida"\s*:\s*estado\["vida"\]\s*,\s*'
                r'"cartas_desbloqueadas"\s*:\s*\[\]\s*\}'
            ),
        )

    def test_despido_registra_muerte_antes_del_reset(self) -> None:
        inicio = self.acusacion.index("static func perder_vida(")
        fin = self.acusacion.index("## Cierra el careo", inicio)
        bloque = self.acusacion[inicio:fin]
        muerte = bloque.index(
            'Prometeo.desbloquear_carta_en_estado(estado, "la-muerte")'
        )
        reset = bloque.index("Prometeo.reiniciar_vuelta")
        self.assertLess(muerte, reset)
        self.assertRegex(
            bloque,
            re.compile(
                r'return\s*\{\s*"despido"\s*:\s*true\s*,\s*'
                r'"vida"\s*:\s*estado\["vida"\]\s*,\s*'
                r'"cartas_desbloqueadas"\s*:\s*\[\]\s*\}'
            ),
        )

    def test_acusacion_propaga_cartas_de_la_perdida_antes_del_reset(self) -> None:
        inicio = self.acusacion.index("static func acusar(")
        fin = self.acusacion.index("## Quita vidas", inicio)
        bloque = self.acusacion[inicio:fin]
        self.assertNotIn(
            'estado["perdio_vida_en_esta_vuelta"] = true',
            bloque,
        )
        castigo = bloque.index("castigo = perder_vida(estado, jornada, 1)")
        propaga_match = re.search(
            r'for\s+carta_id\s+in\s+castigo\.get\(\s*'
            r'"cartas_desbloqueadas"\s*,\s*\[\]\s*\)\s*:',
            bloque,
        )
        self.assertIsNotNone(propaga_match)
        propaga = propaga_match.start()
        limpia = bloque.index("cartas_desbloqueadas.clear()")
        self.assertLess(castigo, propaga)
        self.assertLess(propaga, limpia)

    def test_victoria_de_careo_emite_colgado_solo_al_ganar(self) -> None:
        inicio = self.acusacion.index("static func resolver_duelo(")
        fin = self.acusacion.index("## A quién se puede acusar", inicio)
        bloque = self.acusacion[inicio:fin]
        gana = bloque.index("if gano:")
        desbloqueo = bloque.index(
            'Prometeo.desbloquear_carta_en_estado(estado, "el-colgado")'
        )
        derrota = bloque.index("return perder_vida")
        self.assertLess(gana, desbloqueo)
        self.assertLess(desbloqueo, derrota)
        self.assertIn('cartas_desbloqueadas.append("el-colgado")', bloque)

    def test_visores_notifican_evento_antes_del_guardado(self) -> None:
        for fuente in (self.visor, self.visor_sello):
            firma_inicio = fuente.index("func _al_firmar(")
            firma_fin = fuente.index("\n\nfunc ", firma_inicio)
            firma = fuente[firma_inicio:firma_fin]
            self.assertLess(
                firma.index("_notificar_cartas_desbloqueadas(resultado)"),
                firma.index("_guardar_o_avisar()"),
            )

            careo_inicio = fuente.index("func _al_terminar_careo(")
            careo_fin = fuente.index("\n\nfunc ", careo_inicio)
            careo = fuente[careo_inicio:careo_fin]
            self.assertLess(
                careo.index("_notificar_cartas_desbloqueadas(duelo)"),
                careo.index("_guardar_o_avisar()"),
            )

    def test_memoria_fantasma_vive_en_frontera_comun(self) -> None:
        inicio = self.prometeo.index("static func desbloquear_carta_en_estado(")
        fin = self.prometeo.index("## Familia de progreso", inicio)
        bloque = self.prometeo[inicio:fin]
        self.assertLess(
            bloque.index("if not desbloquear_carta(tarot, id)"),
            bloque.index('estado.get("cartas_conocidas", [])'),
        )
        self.assertIn("if not conocidas.has(id)", bloque)
        self.assertIn("conocidas.append(id)", bloque)
        self.assertIn('estado["cartas_conocidas"] = conocidas', bloque)

    def test_hallazgo_oculto_usa_misma_memoria_sin_mezclar_trigger(self) -> None:
        inicio = self.visor.index("func _al_encontrar_carta(")
        fin = self.visor.index("## Hook de dominio", inicio)
        bloque = self.visor[inicio:fin]
        self.assertIn(
            "Prometeo.desbloquear_carta_en_estado(partida.estado, carta_id)", bloque
        )
        self.assertNotIn("cartas_conocidas", bloque)
        self.assertIn("_abrir_historia(carta_id)", bloque)

    def test_no_sincroniza_por_pistas_al_cargar_ni_abrir_ui(self) -> None:
        inicio = self.visor.index("func _ready()")
        fin = self.visor.index("func _draw()", inicio)
        bloque = self.visor[inicio:fin]
        self.assertNotIn("sincronizar_tarot_por_pistas", bloque)
        self.assertNotIn("sincronizar_tarot_por_caso_resuelto", bloque)

    def test_dispatch_reconoce_el_nombre_documentado_de_progreso(self) -> None:
        self.assertIn('destino.contains("tarot")', self.capturar)
        self.assertIn('destino.contains("progreso")', self.capturar)
        self.assertNotIn('destino.contains("tarot-progreso")', self.capturar)

    def test_qa_obtiene_la_carta_por_pista_antes_de_renderizarla(self) -> None:
        inicio = self.capturar.index("func _capturar_tarot_progreso(")
        fin = self.capturar.index("func _primera_pista_capturable", inicio)
        bloque = self.capturar[inicio:fin]
        self.assertLess(bloque.index('_al_pulsar_marca("pista:'), bloque.index('escena._carta_de('))
        self.assertLess(bloque.index('escena._carta_de('), bloque.index("TarotCinematica.planos_de"))
        self.assertIn('carta.get("recogida", false)', bloque)
        self.assertIn('conocidas.has("el-mago")', bloque)
        self.assertNotIn('["recogida"] = true', bloque)
        self.assertNotIn('desbloquear_carta(', bloque)


if __name__ == "__main__":
    unittest.main()
