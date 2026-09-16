import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "correo_corporativo.json"
TEXTOS = ROOT / "godot" / "datos" / "correo_siga_textos.json"
MODELO = ROOT / "godot" / "guion" / "correo_siga_modelo.gd"
CLIENTE = ROOT / "godot" / "guion" / "correo_siga.gd"
ADAPTADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"
COMPANEROS = ROOT / "godot" / "guion" / "companeros.gd"


def cargar_mensajes() -> list[dict]:
    return json.loads(CATALOGO.read_text(encoding="utf-8"))["mensajes"]


def entregados(
    mensajes: list[dict], dia: int, acciones: int, presentes: set[str]
) -> list[str]:
    ids: list[str] = []
    for mensaje in mensajes:
        dia_entrega = int(mensaje["dia_entrega"])
        if dia < dia_entrega:
            continue
        if dia == dia_entrega and acciones > int(mensaje["acciones_max"]):
            continue
        companero = mensaje.get("companero_id")
        if companero and companero not in presentes:
            continue
        ids.append(mensaje["id"])
    return ids


class CorreoSigaTest(unittest.TestCase):
    def test_catalogo_es_declarativo_y_tiene_ids_estables(self) -> None:
        mensajes = cargar_mensajes()
        self.assertGreaterEqual(len(mensajes), 12)
        ids = [mensaje["id"] for mensaje in mensajes]
        self.assertEqual(len(ids), len(set(ids)))
        for mensaje in mensajes:
            self.assertTrue(mensaje["remitente"])
            self.assertTrue(mensaje["asunto"])
            self.assertTrue(mensaje["cuerpo"])
            self.assertRegex(mensaje["hora"], r"\A\d\d:\d\d\Z")
            self.assertIsInstance(mensaje["dia_entrega"], int)
            self.assertIsInstance(mensaje["acciones_max"], int)
            self.assertIs(mensaje["importancia_narrativa"], False)

    def test_los_companeros_del_correo_existen_en_la_plantilla_real(self) -> None:
        fuente = COMPANEROS.read_text(encoding="utf-8")
        ids_reales = set(re.findall(r'"id": "([a-z0-9_]+)"', fuente))
        ids_correo = {
            mensaje["companero_id"]
            for mensaje in cargar_mensajes()
            if mensaje.get("companero_id")
        }
        self.assertLessEqual(ids_correo, ids_reales)
        self.assertIn("cunado", ids_correo)
        self.assertGreaterEqual(len(ids_correo), 8)

    def test_el_correo_aparece_segun_avanza_la_jornada(self) -> None:
        mensajes = cargar_mensajes()
        presentes = {"cunado", "becario", "telefono"}

        al_entrar = entregados(mensajes, dia=1, acciones=3, presentes=presentes)
        tras_una_accion = entregados(mensajes, dia=1, acciones=2, presentes=presentes)
        tarde = entregados(mensajes, dia=1, acciones=1, presentes=presentes)
        agotada = entregados(mensajes, dia=1, acciones=0, presentes=presentes)

        self.assertEqual(al_entrar, ["sistema-buzon-alta"])
        self.assertIn("cunado-asuntos-mayusculas", tras_una_accion)
        self.assertIn("telefono-centralita", tras_una_accion)
        self.assertNotIn("becario-listado", tras_una_accion)
        self.assertIn("becario-listado", tarde)
        self.assertIn("spam-modem-56k", tarde)
        self.assertNotIn("sistema-cierre-dia1", tarde)
        self.assertIn("sistema-cierre-dia1", agotada)

    def test_un_mensaje_entregado_no_desaparece_al_dia_siguiente(self) -> None:
        mensajes = cargar_mensajes()
        presentes = {"cunado", "becario", "telefono"}
        dia_dos = entregados(mensajes, dia=2, acciones=3, presentes=presentes)
        self.assertIn("sistema-cierre-dia1", dia_dos)
        self.assertIn("rrhh-formacion", dia_dos)

    def test_no_entran_correos_de_companeros_que_no_estan_en_esta_vuelta(self) -> None:
        mensajes = cargar_mensajes()
        presentes = {"cunado", "becario", "telefono"}
        dia_tres = entregados(mensajes, dia=3, acciones=0, presentes=presentes)
        self.assertNotIn("emperador-orden-carpetas", dia_tres)
        self.assertNotIn("riegos-consulta", dia_tres)
        self.assertNotIn("fielato-sueno", dia_tres)

    def test_modelo_no_depende_del_reloj_real(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn("Jornada.ACCIONES_POR_DIA", fuente)
        self.assertIn('"acciones"', fuente)
        self.assertIn('"dia"', fuente)
        self.assertNotIn("Time.get_", fuente)
        self.assertNotIn("OS.get_", fuente)
        self.assertIn("_corresponde_a_plantilla", fuente)

    def test_cliente_marca_no_leidos_sin_depender_solo_del_color(self) -> None:
        fuente = CLIENTE.read_text(encoding="utf-8")
        textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        self.assertEqual(textos["marca_nuevo"], "[NUEVO] ")
        self.assertIn("item_selected.connect", fuente)
        self.assertIn("signal mensaje_leido", fuente)
        self.assertIn("selection_enabled = true", fuente)
        self.assertIn('texto("marca_nuevo")', fuente)

    def test_adaptador_registra_correo_y_persiste_por_partida(self) -> None:
        fuente = ADAPTADOR.read_text(encoding="utf-8")
        self.assertRegex(
            fuente,
            r'EscritorioSigaApp\.new\(\s*"correo",\s*CorreoSiga\.texto\("titulo_app"\)',
        )
        self.assertIn("_correo_app.persistir_estado = true", fuente)
        self.assertIn('obtener_estado_local("leidos_por_partida", {})', fuente)
        self.assertIn(
            '_correo_app.establecer_estado_local("leidos_por_partida", por_partida)',
            fuente,
        )
        self.assertIn('dia.jornada.get("raiz", 0)', fuente)
        self.assertIn("Companeros.plantilla", fuente)
        self.assertIn("correo.configurar_contexto(dia.jornada, presentes)", fuente)

    def test_contrato_de_entrega_ejecutable_en_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_correo_siga.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("13 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
