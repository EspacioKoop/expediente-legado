import unittest

from scripts.auditar_backlog import analizar_issues, render_markdown


def issue(numero, *labels, body="", title=None, pull_request=False):
    valor = {
        "number": numero,
        "title": title or f"Issue {numero}",
        "body": body,
        "labels": [{"name": label} for label in labels],
    }
    if pull_request:
        valor["pull_request"] = {"url": "https://example.invalid/pr"}
    return valor


class AuditarBacklogTest(unittest.TestCase):
    def test_separa_gates_humanos_de_features_y_prs(self):
        resultado = analizar_issues(
            [
                issue(9, "prioridad:P0", "estado:validacion-humana"),
                issue(20, "estado:validacion-humana"),
                issue(21, "prioridad:P0"),
                issue(22, "prioridad:P0", pull_request=True),
            ]
        )
        self.assertEqual(resultado["open_count"], 3)
        self.assertEqual(resultado["wip_count"], 1)
        self.assertEqual(
            [valor["number"] for valor in resultado["human_candidates"]],
            [20],
        )

    def test_duplicado_abierto_es_alerta_dura(self):
        resultado = analizar_issues([issue(30, "duplicado-o-sustituido")])
        self.assertTrue(resultado["hard_alert"])
        self.assertEqual(resultado["duplicates_count"], 1)

    def test_parcial_y_bloqueado_exigen_contexto(self):
        resultado = analizar_issues(
            [
                issue(40, "estado:parcial", body="Falta pulir algo."),
                issue(41, "estado:parcial", body="## Siguiente corte\nImplementar X."),
                issue(42, "estado:bloqueado", body="Esperar."),
                issue(43, "estado:bloqueado", body="Se desbloquea al mergear #12."),
            ]
        )
        self.assertEqual(
            [valor["number"] for valor in resultado["partial_without_next_cut"]],
            [40],
        )
        self.assertEqual(
            [valor["number"] for valor in resultado["blocked_without_condition"]],
            [42],
        )

    def test_markdown_expone_limite_wip(self):
        resultado = analizar_issues([issue(50, "prioridad:P1")])
        texto = render_markdown(resultado)
        self.assertIn("WIP técnico ejecutable: **1 / 15**", texto)
        self.assertIn("#50", texto)


if __name__ == "__main__":
    unittest.main()
