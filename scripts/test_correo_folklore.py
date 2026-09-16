import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "godot" / "datos" / "correo_folklore.json"
MODELO = ROOT / "godot" / "guion" / "correo_siga_modelo.gd"

ESTADOS = {"rumor", "desmentido", "broma", "desconocido"}


def cargar_mensajes() -> list[dict]:
    return json.loads(CATALOGO.read_text(encoding="utf-8"))["mensajes"]


class CorreoFolkloreTest(unittest.TestCase):
    def test_hay_al_menos_ocho_mensajes_originales_de_folklore(self) -> None:
        mensajes = cargar_mensajes()
        self.assertGreaterEqual(len(mensajes), 8)
        self.assertTrue(all(m["id"].startswith("folklore-") for m in mensajes))
        self.assertTrue(all(m["folklore_digital"] is True for m in mensajes))
        self.assertTrue(all(m["importancia_narrativa"] is False for m in mensajes))
        self.assertTrue(all(m["adjunto"] == "" for m in mensajes))

    def test_estado_interno_es_valido_y_no_se_expone_como_tipo(self) -> None:
        for mensaje in cargar_mensajes():
            self.assertIn(mensaje["estado_folklore"], ESTADOS)
            self.assertNotEqual(mensaje["tipo"], mensaje["estado_folklore"])

    def test_relaciones_solo_apuntan_a_mensajes_existentes(self) -> None:
        mensajes = cargar_mensajes()
        ids = {m["id"] for m in mensajes}
        for mensaje in mensajes:
            for relacionado in mensaje.get("relacionados", []):
                self.assertIn(relacionado, ids)
            reenvio = mensaje.get("reenvio_de")
            if reenvio:
                self.assertIn(reenvio, ids)

    def test_hay_rumor_y_desmentido_posterior_en_la_misma_cadena(self) -> None:
        por_cadena: dict[str, list[dict]] = {}
        for mensaje in cargar_mensajes():
            por_cadena.setdefault(mensaje["cadena_id"], []).append(mensaje)

        cadenas_desmentidas = []
        for cadena_id, mensajes in por_cadena.items():
            rumores = [m for m in mensajes if m["estado_folklore"] == "rumor"]
            desmentidos = [m for m in mensajes if m["estado_folklore"] == "desmentido"]
            if not rumores or not desmentidos:
                continue
            primer_rumor = min((m["dia_entrega"], -m["acciones_max"]) for m in rumores)
            ultimo_desmentido = max(
                (m["dia_entrega"], -m["acciones_max"]) for m in desmentidos
            )
            if ultimo_desmentido > primer_rumor:
                cadenas_desmentidas.append(cadena_id)

        self.assertIn("virus-paraguas-gris", cadenas_desmentidas)

    def test_companeros_reaccionan_de_formas_distintas(self) -> None:
        reacciones = {
            m["companero_id"]: m["estado_folklore"]
            for m in cargar_mensajes()
            if m.get("companero_id")
        }
        self.assertIn("cunado", reacciones)
        self.assertIn("becario", reacciones)
        self.assertIn("correspondencia", reacciones)
        self.assertIn("riegos", reacciones)
        self.assertGreaterEqual(len(set(reacciones.values())), 3)

    def test_ignorar_folklore_no_introduce_progreso_ni_adjuntos(self) -> None:
        campos_prohibidos = {
            "pista",
            "pistas",
            "recompensa",
            "progreso",
            "desbloquea",
            "estado_campana",
            "accion_obligatoria",
        }
        for mensaje in cargar_mensajes():
            self.assertTrue(campos_prohibidos.isdisjoint(mensaje))
            self.assertFalse(mensaje["importancia_narrativa"])
            self.assertEqual(mensaje["adjunto"], "")

    def test_el_desmentido_de_sistemas_no_depende_de_un_companero(self) -> None:
        mensajes = {m["id"]: m for m in cargar_mensajes()}
        desmentido = mensajes["folklore-sistemas-desmiente-paraguas"]
        self.assertNotIn("companero_id", desmentido)
        self.assertEqual(desmentido["estado_folklore"], "desmentido")
        self.assertGreater(
            desmentido["dia_entrega"],
            mensajes["folklore-cunado-virus-paraguas"]["dia_entrega"],
        )

    def test_modelo_carga_folklore_solo_en_el_catalogo_principal(self) -> None:
        fuente = MODELO.read_text(encoding="utf-8")
        self.assertIn('RUTA_FOLKLORE := "res://datos/correo_folklore.json"', fuente)
        self.assertIn("if ruta == RUTA_CATALOGO:", fuente)
        self.assertIn("_mensajes.append_array(_cargar_catalogo(RUTA_FOLKLORE))", fuente)


if __name__ == "__main__":
    unittest.main()
