import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

import scripts.gestionar_reservas as base
import scripts.gestionar_reservas_rollover as rollover


class ReservasRolloverTest(unittest.TestCase):
    def test_config_declara_registro_activo_y_lectura_historica(self):
        activo, lectura = rollover.cargar_config()
        self.assertEqual(activo, 1713)
        self.assertEqual(lectura, [182, 1713])

    def test_config_rechaza_duplicados(self):
        with TemporaryDirectory() as tmp:
            ruta = Path(tmp) / "config.json"
            ruta.write_text(
                json.dumps({"active": 1713, "read": [182, 1713, 1713]}),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                rollover.cargar_config(ruta)

    def test_combina_registro_historico_y_activo_en_orden(self):
        respuestas = {
            "/issues/182/comments?per_page=100&page=1": [
                {"id": 10, "created_at": "2026-09-28T10:00:00Z", "body": "viejo", "author_association": "MEMBER", "user": {"login": "maintainer"}}
            ],
            "/issues/1713/comments?per_page=100&page=1": [
                {"id": 20, "created_at": "2026-09-28T11:00:00Z", "body": "nuevo", "author_association": "NONE", "user": {"login": "github-actions[bot]"}}
            ],
        }

        def api(_method, path, _payload=None):
            sufijo = path.split("/repos/x/y", 1)[-1]
            return respuestas[sufijo], {}

        with patch.object(base, "REPO", "x/y"), patch.object(base, "api_json", api):
            comentarios = rollover.obtener_comentarios([182, 1713])
        self.assertEqual([c["id"] for c in comentarios], [10, 20])

    def test_filtra_comentario_externo_del_historial(self):
        respuestas = {
            "/issues/182/comments?per_page=100&page=1": [
                {"id": 10, "created_at": "2026-09-28T10:00:00Z", "body": "CLAIM issue=#9 agent=X branch=x files=a goal=a", "author_association": "NONE", "user": {"login": "externo"}}
            ],
        }

        def api(_method, path, _payload=None):
            sufijo = path.split("/repos/x/y", 1)[-1]
            return respuestas.get(sufijo, []), {}

        with patch.object(base, "REPO", "x/y"), patch.object(base, "api_json", api):
            comentarios = rollover.obtener_comentarios([182])
        self.assertEqual([], comentarios)

    def test_gestion_publica_release_solo_en_registro_activo(self):
        comentarios = [
            {
                "id": 10,
                "created_at": "2026-09-28T10:00:00Z",
                "body": (
                    "CLAIM issue=#91 agent=A branch=feat/91-x "
                    "files=a.gd goal=x lease=48h"
                ),
                "author_association": "MEMBER",
                "user": {"login": "maintainer"},
            },
            {
                "id": 20,
                "created_at": "2026-09-28T11:00:00Z",
                "body": "PR_READY issue=#91 pr=#200 sha=abc pruebas=ok limites=ninguno",
                "author_association": "NONE",
                "user": {"login": "github-actions[bot]"},
            },
        ]
        llamadas = []

        def api(method, path, payload=None, dormir=None):
            llamadas.append((method, path, payload))
            if "/pulls/200" in path:
                return {
                    "number": 200,
                    "state": "closed",
                    "merged_at": "2026-09-28T12:00:00Z",
                    "merge_commit_sha": "deadbeef",
                    "head": {"ref": "feat/91-x"},
                }, {}
            if method == "POST":
                return {}, {}
            if "/issues/91" in path:
                return {"labels": []}, {}
            return [], {}

        with (
            patch.object(rollover, "obtener_comentarios", return_value=comentarios),
            patch.object(base, "api_json", api),
            patch.object(base, "REPO", "x/y"),
        ):
            codigo = rollover.ejecutar_gestion(
                numero_pr=200,
                barrer=False,
                legacy_cutoff=None,
                dry_run=False,
            )
        self.assertEqual(codigo, 0)
        posts = [path for method, path, _ in llamadas if method == "POST"]
        self.assertTrue(any(path.endswith("/issues/1713/comments") for path in posts))
        self.assertFalse(any(path.endswith("/issues/182/comments") for path in posts))


if __name__ == "__main__":
    unittest.main()
