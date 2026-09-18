from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
CAPTURAR = ROOT / "godot" / "pruebas" / "capturar.gd"


class TarotProgresion1029Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.capturar = CAPTURAR.read_text(encoding="utf-8")

    def test_primera_pista_sincroniza_antes_del_guardado(self) -> None:
        inicio = self.visor.index('\t\t"pista":')
        fin = self.visor.index('\t\t"carta":', inicio)
        bloque = self.visor[inicio:fin]
        self.assertLess(bloque.index("descubiertas.append"), bloque.index("_sincronizar_tarot_por_pista()"))
        self.assertLess(bloque.index("_sincronizar_tarot_por_pista()"), bloque.index("_guardar_o_avisar()"))

    def test_el_mago_es_per_run_y_memoria_fantasma_sin_historia_oculta(self) -> None:
        inicio = self.visor.index("func _sincronizar_tarot_por_pista()")
        fin = self.visor.index("## Encontrar una carta escondida", inicio)
        bloque = self.visor[inicio:fin]
        self.assertIn('Prometeo.desbloquear_carta(tarot, "el-mago")', bloque)
        self.assertIn('partida.estado.get("cartas_conocidas", [])', bloque)
        self.assertIn('conocidas.append("el-mago")', bloque)
        self.assertNotIn('_al_encontrar_carta("el-mago")', bloque)
        self.assertNotIn('_abrir_historia("el-mago")', bloque)

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
