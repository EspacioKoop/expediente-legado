from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ACUSACION = (ROOT / "godot/guion/acusacion.gd").read_text(encoding="utf-8")
PARTIDA = (ROOT / "godot/guion/partida.gd").read_text(encoding="utf-8")
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
VISOR = (ROOT / "godot/guion/visor_sello_app.gd").read_text(encoding="utf-8")
UI = (ROOT / "godot/guion/ultimo_recurso_app.gd").read_text(encoding="utf-8")
PROMETEO = (ROOT / "godot/guion/prometeo.gd").read_text(encoding="utf-8")


def bloque(fuente: str, inicio: str, fin: str) -> str:
    i = fuente.index(inicio)
    j = fuente.index(fin, i)
    return fuente[i:j]


class UltimoRecurso1205Test(unittest.TestCase):
    def test_cero_es_estado_persistente_y_no_reset(self) -> None:
        perder = bloque(
            ACUSACION,
            "static func perder_vida(",
            "## La frontera pendiente",
        )
        self.assertIn('estado[CLAVE_DESPIDO_PENDIENTE] = true', perder)
        self.assertIn('"despido_pendiente": true', perder)
        self.assertIn('"vida": 0', perder)
        self.assertNotIn("reiniciar_vuelta", perder)
        self.assertNotIn('"la-muerte"', perder)

        self.assertIn('"despido_pendiente": false', PARTIDA)
        self.assertIn('guardado.has("despido_pendiente")', PARTIDA)
        self.assertIn("for clave in fusionado:", PARTIDA)

    def test_canje_es_unico_emisor_de_templanza_en_esta_frontera(self) -> None:
        canje = bloque(
            ACUSACION,
            "static func canjear_carta_por_vida(",
            "## Aceptar el cese",
        )
        self.assertIn('elegida["gastada"] = true', canje)
        self.assertIn('estado["vida"] = 1', canje)
        self.assertIn(
            'desbloquear_carta_en_estado(estado, "la-templanza")',
            canje,
        )
        self.assertNotIn("reiniciar_vuelta", canje)
        self.assertNotIn('"la-muerte"', canje)

        mundo = bloque(
            PROMETEO,
            "static func sincronizar_tarot_mundo(",
            "## Una acusación es precipitada",
        )
        self.assertIn('["el-mundo", "la-templanza"]', mundo)
        self.assertNotIn(
            'desbloquear_carta_en_estado(estado, "la-templanza")',
            mundo,
        )

    def test_cese_es_la_unica_salida_que_reinicia_y_concede_muerte(self) -> None:
        cese = bloque(
            ACUSACION,
            "static func aceptar_cese(",
            "## Cierra el careo",
        )
        self.assertIn(
            'desbloquear_carta_en_estado(estado, "la-muerte")',
            cese,
        )
        self.assertIn("EvaluacionDesempeno.sellar", cese)
        self.assertIn("Prometeo.reiniciar_vuelta", cese)
        self.assertIn("Jornada.reiniciar_vuelta", cese)
        self.assertLess(
            cese.index('"la-muerte"'),
            cese.index("Prometeo.reiniciar_vuelta"),
        )

    def test_ui_solo_solicita_y_delega_reglas_al_dominio(self) -> None:
        self.assertIn("signal canje_solicitado", UI)
        self.assertIn("signal cese_solicitado", UI)
        self.assertIn("Acusacion.cartas_canjeables(_estado)", UI)
        self.assertIn('call_deferred("grab_focus")', UI)
        self.assertNotIn("canjear_carta_por_vida", UI)
        self.assertNotIn("aceptar_cese", UI)

    def test_recarga_y_visor_recuperan_la_misma_decision(self) -> None:
        ready = bloque(DIA, "func _ready()", "## Recupera o presenta")
        self.assertIn("Acusacion.despido_pendiente(partida.estado)", ready)
        self.assertIn("_abrir_ultimo_recurso_pendiente()", ready)

        sello = bloque(
            VISOR,
            "func _al_terminar_sello(",
            "func _abrir_careo_firmado(",
        )
        remate = bloque(
            VISOR,
            "func _al_terminar_remate(",
            "## La misma superficie",
        )
        self.assertIn('resultado.get("despido_pendiente", false)', sello)
        self.assertIn('duelo.get("despido_pendiente", false)', remate)
        self.assertIn("_abrir_ultimo_recurso", sello)
        self.assertIn("_abrir_ultimo_recurso", remate)


if __name__ == "__main__":
    unittest.main()
