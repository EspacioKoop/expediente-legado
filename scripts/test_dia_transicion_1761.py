from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"
DIA = (GUION / "dia_app.gd").read_text(encoding="utf-8")
TRANSICION = (GUION / "dia_transicion_app.gd").read_text(encoding="utf-8")
SUBCLASES = {
    nombre: (GUION / f"{nombre}.gd").read_text(encoding="utf-8")
    for nombre in (
        "dia_sueno_app",
        "dia_clima_app",
        "dia_onboarding_app",
        "dia_ascensor_app",
        "dia_alquiler_app",
        "dia_trabajillos_app",
    )
}


def bloque_funcion(fuente: str, nombre: str) -> str:
    inicio = fuente.index(f"func {nombre}(")
    siguiente = fuente.find("\nfunc ", inicio + 5)
    return fuente[inicio:] if siguiente < 0 else fuente[inicio:siguiente]


class DiaTransicion1761Test(unittest.TestCase):
    def test_dia_app_conserva_wrapper_y_delega_resolucion_base(self):
        salida = bloque_funcion(DIA, "_al_pisar_salida")
        self.assertLess(len(DIA.splitlines()), 820)
        self.assertIn(
            'const DIA_TRANSICION_APP = preload("res://guion/dia_transicion_app.gd")',
            DIA,
        )
        self.assertIn("DIA_TRANSICION_APP", salida)
        self.assertIn(". resolver(", salida)
        self.assertIn("_entrar_en(destino)", salida)
        self.assertIn('_guardar_o_avisar("")', salida)

    def test_interactuables_se_resuelven_antes_de_delegar_transicion(self):
        salida = bloque_funcion(DIA, "_al_pisar_salida")
        delegado = salida.index("DIA_TRANSICION_APP")
        for contrato in (
            "partida.guardado_pendiente",
            'salida.get_meta("frase")',
            'salida.get_meta("duelo", "")',
            'destino == "expediente"',
            'destino == "cuenco"',
        ):
            self.assertLess(salida.index(contrato), delegado)

    def test_helper_conserva_orden_archivo(self):
        archivo = TRANSICION.index('"archivo":')
        casa = TRANSICION.index('"casa":', archivo)
        bloque = TRANSICION[archivo:casa]
        orden = (
            '_llamar(acciones, "registrar_firma")',
            "Auditorias.resolver_fin_archivo(estado_partida)",
            "PronosticosAuditoria.resolver_fin_jornada(estado_partida)",
            "Jornada.fichar_salida(jornada)",
        )
        posiciones = [bloque.index(token) for token in orden]
        self.assertEqual(posiciones, sorted(posiciones))

    def test_helper_conserva_orden_casa(self):
        casa = TRANSICION.index('"casa":')
        sueno = TRANSICION.index('"sueño":', casa)
        bloque = TRANSICION[casa:sueno]
        orden = (
            "Auditorias.resolver_fin_casa(estado_partida)",
            "Jornada.dormir(jornada)",
            '_llamar(acciones, "aplicar_politica_sueno")',
        )
        posiciones = [bloque.index(token) for token in orden]
        self.assertEqual(posiciones, sorted(posiciones))

    def test_helper_conserva_despertar_normal(self):
        sueno = TRANSICION.index('"sueño":')
        bloque = TRANSICION[sueno:]
        orden = (
            "pop_front()",
            '_llamar(acciones, "registrar_despertar")',
            "Auditorias.resolver_fin_sueno(estado_partida, true)",
            "EcosDespertarRuntime.preparar_despertar(jornada)",
            "Jornada.despertar(jornada)",
            "Prometeo.reiniciar_exposicion_ideologica_diaria(estado_partida)",
        )
        posiciones = [bloque.index(token) for token in orden]
        self.assertEqual(posiciones, sorted(posiciones))

    def test_helper_no_conoce_nodos_guardado_ni_subclases(self):
        self.assertLess(len(TRANSICION.splitlines()), 100)
        for prohibido in (
            "Node3D",
            "Area3D",
            "Partida.new(",
            "partida.guardar(",
            "_entrar_en(",
            "_guardar_o_avisar",
            "queue_free(",
            "get_node",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, TRANSICION)

    def test_cadena_heredable_sigue_reinyectando_el_evento_oficial(self):
        self.assertIn("func _al_pisar_salida(cuerpo: Node3D, salida: Area3D)", DIA)
        for nombre, fuente in SUBCLASES.items():
            with self.subTest(subclase=nombre):
                self.assertIn("super._al_pisar_salida(cuerpo, salida)", fuente)

    def test_wrapper_conserva_orden_final_entrar_y_guardar(self):
        salida = bloque_funcion(DIA, "_al_pisar_salida")
        delegado = salida.index("DIA_TRANSICION_APP")
        entrar = salida.index("_entrar_en(destino)", delegado)
        guardar = salida.index('_guardar_o_avisar("")', entrar)
        self.assertLess(delegado, entrar)
        self.assertLess(entrar, guardar)


if __name__ == "__main__":
    unittest.main()
