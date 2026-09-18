from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
PROMETEO = ROOT / "godot" / "guion" / "prometeo.gd"
CAPTURAR = ROOT / "godot" / "pruebas" / "capturar.gd"


class TarotProgresion1029Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.visor = VISOR.read_text(encoding="utf-8")
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
        self.assertIn("_al_carta_desbloqueada(carta_id)", bloque)
        self.assertNotIn("cartas_conocidas", bloque)
        self.assertNotIn("_al_encontrar_carta", bloque)
        self.assertNotIn("_abrir_historia", bloque)

    def test_regla_por_pistas_cubre_mago_y_estrella_idempotentes(self) -> None:
        inicio = self.prometeo.index("static func sincronizar_tarot_por_pistas(")
        fin = self.prometeo.index("## Una acusación es precipitada", inicio)
        bloque = self.prometeo[inicio:fin]
        self.assertIn('pistas.size() >= 1', bloque)
        self.assertIn('desbloquear_carta_en_estado(estado, "el-mago")', bloque)
        self.assertIn('pistas.size() >= 20', bloque)
        self.assertIn('desbloquear_carta_en_estado(estado, "la-estrella")', bloque)
        self.assertEqual(bloque.count('nuevas.append("el-mago")'), 1)
        self.assertEqual(bloque.count('nuevas.append("la-estrella")'), 1)

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
        self.assertNotIn("sincronizar_tarot_por_pistas", self.visor[inicio:fin])

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
