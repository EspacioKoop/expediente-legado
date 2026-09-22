import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
CONTAMINACION = ROOT / "godot" / "guion" / "contaminacion_os98.gd"
PROMETEO = ROOT / "godot" / "guion" / "prometeo.gd"
PRUEBA_GODOT = "pruebas/pruebas_contaminacion_os98.gd"


def bloque(fuente: str, inicio: str, fin: str) -> str:
    desde = fuente.index(inicio)
    hasta = fuente.index(fin, desde)
    return fuente[desde:hasta]


class TarotEmperador1029Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.adaptador = ADAPTADOR.read_text(encoding="utf-8")
        cls.contaminacion = CONTAMINACION.read_text(encoding="utf-8")
        cls.prometeo = PROMETEO.read_text(encoding="utf-8")

    def test_frontera_admin_es_el_primer_acceso_restringido_real(self) -> None:
        registrar = bloque(
            self.contaminacion,
            "static func registrar_ruta(",
            "static func _avanzar(",
        )
        self.assertIn('ruta != RUTA_RESTRINGIDA', registrar)
        self.assertIn('estado.get("credencial_descubierta", false)', registrar)
        self.assertIn('estado.get("acceso_restringido_usado", false)', registrar)
        self.assertIn('estado["acceso_restringido_usado"] = true', registrar)
        self.assertIn('return true', registrar)

    def test_memorandum_y_contexto_no_conceden_emperador(self) -> None:
        documentos = bloque(
            self.adaptador,
            "func _registrar_documento_os98(",
            "func _registrar_ruta_os98(",
        )
        contexto = bloque(
            self.adaptador,
            "func _contexto_os98(",
            "func _estado_os98(",
        )
        for seccion in (documentos, contexto):
            self.assertNotIn('"el-emperador"', seccion)
            self.assertNotIn("desbloquear_carta_en_estado", seccion)

    def test_acceso_real_delega_solo_despues_del_hito_restringido(self) -> None:
        acceso = bloque(
            self.adaptador,
            "func _registrar_ruta_os98(",
            "func _sincronizar_contexto_os98(",
        )
        evento = acceso.index("ContaminacionOs98.registrar_ruta(estado, ruta)")
        efecto = acceso.index("_al_acceso_administrativo(")
        self.assertLess(evento, efecto)
        self.assertNotIn('"el-emperador"', acceso)
        self.assertNotIn("_guardar_o_avisar", acceso)

    def test_efecto_admin_concede_emperador_evalua_mundo_y_guarda(self) -> None:
        efecto = bloque(
            self.adaptador,
            "func _al_acceso_administrativo(",
            "func _registrar_respuesta_correo(",
        )
        persistencia_os = efecto.index("_persistir_estado_os98(dia, estado)")
        emperador = efecto.index(
            'Prometeo.desbloquear_carta_en_estado(partida_estado, "el-emperador")'
        )
        mundo = efecto.index("Prometeo.sincronizar_tarot_mundo(")
        guardado = efecto.index('dia.call("_guardar_o_avisar", "")')

        self.assertLess(persistencia_os, emperador)
        self.assertLess(emperador, mundo)
        self.assertLess(mundo, guardado)
        self.assertIn("Contenido.new()", efecto)
        self.assertIn("contenido.principales()", efecto)

    def test_usa_la_frontera_comun_de_memoria_fantasma(self) -> None:
        acceso = bloque(
            self.adaptador,
            "func _registrar_ruta_os98(",
            "func _sincronizar_contexto_os98(",
        )
        self.assertIn("Prometeo.desbloquear_carta_en_estado", acceso)

        frontera = bloque(
            self.prometeo,
            "static func desbloquear_carta_en_estado(",
            "## Familia de progreso",
        )
        self.assertIn('estado.get("cartas_conocidas", [])', frontera)
        self.assertIn("conocidas.append(id)", frontera)
        self.assertIn('estado["cartas_conocidas"] = conocidas', frontera)

    def test_evento_restringido_sigue_siendo_idempotente_en_godot_real(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
