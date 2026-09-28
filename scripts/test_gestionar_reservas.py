from datetime import datetime, timedelta, timezone
import io
import unittest
from unittest import mock
from urllib.error import HTTPError

import gestionar_reservas as reservas


UTC = timezone.utc


def comentario(body: str, when: datetime) -> dict:
    return {"body": body, "created_at": when.isoformat().replace("+00:00", "Z")}


class GestionarReservasTest(unittest.TestCase):
    def test_claim_parsea_lease_y_release_es_idempotente_en_estado(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario(
                "CLAIM issue=#10 agent=Codex branch=feature/10-a files=a.gd goal=Probar algo lease=48h",
                t0,
            ),
            comentario("RELEASE issue=#10 motivo=entregado", t0 + timedelta(hours=1)),
        ]

        estado = reservas.reconstruir_reservas(comentarios)
        reserva = estado[(10, "feature/10-a")]

        self.assertEqual(48, reserva.lease_hours)
        self.assertEqual("Probar algo", reserva.goal)
        self.assertTrue(reserva.released)

    def test_release_con_branch_no_libera_otro_corte_del_mismo_issue(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario("CLAIM issue=#10 agent=A branch=feature/10-a files=a.gd goal=A lease=48h", t0),
            comentario("CLAIM issue=#10 agent=B branch=feature/10-b files=b.gd goal=B lease=48h", t0),
            comentario(
                "RELEASE issue=#10 motivo=entregado branch=feature/10-a auto=reservas.yml",
                t0 + timedelta(hours=1),
            ),
        ]

        estado = reservas.reconstruir_reservas(comentarios)

        self.assertTrue(estado[(10, "feature/10-a")].released)
        self.assertFalse(estado[(10, "feature/10-b")].released)

    def test_pr_ready_sin_branch_no_adivina_entre_dos_claim_activos(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario(
                "CLAIM issue=#10 agent=A branch=feature/10-a files=a.gd goal=A lease=48h",
                t0,
            ),
            comentario(
                "CLAIM issue=#10 agent=B branch=feature/10-b files=b.gd goal=B lease=48h",
                t0 + timedelta(minutes=1),
            ),
            comentario(
                "PR_READY issue=#10 pr=#100 sha=abc pruebas=ok limites=ninguno",
                t0 + timedelta(minutes=2),
            ),
        ]

        estado = reservas.reconstruir_reservas(comentarios)

        self.assertIsNone(estado[(10, "feature/10-a")].pr)
        self.assertIsNone(estado[(10, "feature/10-b")].pr)

    def test_pr_ready_con_branch_resuelve_el_claim_explicito(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario(
                "CLAIM issue=#10 agent=A branch=feature/10-a files=a.gd goal=A lease=48h",
                t0,
            ),
            comentario(
                "CLAIM issue=#10 agent=B branch=feature/10-b files=b.gd goal=B lease=48h",
                t0 + timedelta(minutes=1),
            ),
            comentario(
                "PR_READY issue=#10 pr=#100 sha=abc pruebas=ok limites=ninguno "
                "branch=feature/10-a",
                t0 + timedelta(minutes=2),
            ),
        ]

        estado = reservas.reconstruir_reservas(comentarios)

        self.assertEqual(100, estado[(10, "feature/10-a")].pr)
        self.assertIsNone(estado[(10, "feature/10-b")].pr)

    def test_heartbeat_renueva_lease(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario(
                "CLAIM issue=#11 agent=Codex branch=feature/11-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("HEARTBEAT issue=#11 branch=feature/11-a", t0 + timedelta(hours=40)),
        ]
        estado = reservas.reconstruir_reservas(comentarios)

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=60),
            lambda _: self.fail("no debe consultar PR"),
        )

        self.assertEqual([], acciones)

    def test_claim_sin_pr_caduca_tras_lease(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#12 agent=Codex branch=feature/12-a files=a.gd goal=Probar lease=48h",
                t0,
            )
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=49),
            lambda _: self.fail("no debe consultar PR"),
        )

        self.assertEqual("reserva-caducada", acciones[0][1])

    def test_pr_abierta_mantiene_reserva_aunque_venza_lease(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#13 agent=Codex branch=feature/13-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("PR_READY issue=#13 pr=#100 sha=abc pruebas=ok limites=ninguno", t0),
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(days=10),
            lambda _: {"number": 100, "state": "open", "merged_at": None},
        )

        self.assertEqual([], acciones)

    def test_pr_mergeada_libera_reserva(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#14 agent=Codex branch=feature/14-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("PR_READY issue=#14 pr=#101 sha=abc pruebas=ok limites=ninguno", t0),
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=1),
            lambda _: {
                "number": 101,
                "state": "closed",
                "merged_at": "2026-09-15T00:30:00Z",
                "merge_commit_sha": "deadbeef",
            },
        )

        self.assertEqual("merge-detectado-automaticamente", acciones[0][1])

    def test_pr_cerrada_sin_merge_libera_reserva(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#15 agent=Codex branch=feature/15-a files=a.gd goal=Probar lease=48h",
                t0,
            ),
            comentario("PR_READY issue=#15 pr=#102 sha=abc pruebas=ok limites=ninguno", t0),
        ])

        acciones = reservas.planificar_barrido(
            estado,
            t0 + timedelta(hours=1),
            lambda _: {"number": 102, "state": "closed", "merged_at": None},
        )

        self.assertEqual("PR-cerrado-sin-integrar", acciones[0][1])

    def test_migracion_libera_claim_legacy_anterior_al_corte(self):
        t0 = datetime(2026, 9, 14, 0, 0, tzinfo=UTC)
        cutoff = datetime(2026, 9, 15, 4, 6, 30, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario("CLAIM issue=#16 agent=Codex branch=feature/16-a files=a.gd goal=Legacy", t0)
        ])

        acciones = reservas.planificar_barrido(
            estado,
            cutoff + timedelta(hours=1),
            lambda _: self.fail("no debe consultar PR"),
            legacy_cutoff=cutoff,
        )

        self.assertEqual("migracion-legacy-sin-trabajo-activo", acciones[0][1])

    def test_migracion_no_libera_claim_legacy_posterior_al_corte(self):
        cutoff = datetime(2026, 9, 15, 4, 6, 30, tzinfo=UTC)
        estado = reservas.reconstruir_reservas([
            comentario(
                "CLAIM issue=#17 agent=Codex branch=feature/17-a files=a.gd goal=Legacy nuevo",
                cutoff + timedelta(minutes=1),
            )
        ])

        acciones = reservas.planificar_barrido(
            estado,
            cutoff + timedelta(hours=3),
            lambda _: self.fail("no debe consultar PR"),
            legacy_cutoff=cutoff,
        )

        self.assertEqual([], acciones)


def http_error(code: int, cuerpo: str, cabeceras: dict[str, str] | None = None) -> HTTPError:
    return HTTPError(
        "https://api.github.com/x", code, "error", cabeceras or {}, io.BytesIO(cuerpo.encode())
    )


SECUNDARIO = (
    '{"message":"You have exceeded a secondary rate limit and have been '
    'temporarily blocked from content creation."}'
)


class ReintentosTest(unittest.TestCase):
    def test_403_de_rate_limit_secundario_es_transitorio_y_el_de_permisos_no(self):
        self.assertTrue(reservas.es_transitorio(403, SECUNDARIO))
        self.assertFalse(reservas.es_transitorio(403, '{"message":"Resource not accessible"}'))
        self.assertTrue(reservas.es_transitorio(429, ""))
        self.assertTrue(reservas.es_transitorio(502, ""))
        self.assertFalse(reservas.es_transitorio(404, ""))

    def test_espera_usa_retry_after_luego_reset_y_si_no_backoff_exponencial(self):
        self.assertEqual(7.0, reservas.espera_recomendada({"Retry-After": "7"}, 0, 1000.0))
        cabeceras = {"x-ratelimit-remaining": "0", "x-ratelimit-reset": "1030"}
        self.assertEqual(30.0, reservas.espera_recomendada(cabeceras, 0, 1000.0))
        self.assertEqual(4.0, reservas.espera_recomendada({}, 2, 1000.0))

    def test_espera_nunca_supera_el_tope(self):
        self.assertEqual(
            reservas.ESPERA_MAX_SEGUNDOS,
            reservas.espera_recomendada({"Retry-After": "99999"}, 0, 1000.0),
        )
        self.assertEqual(reservas.ESPERA_MAX_SEGUNDOS, reservas.espera_recomendada({}, 20, 1000.0))

    def test_api_json_reintenta_el_rate_limit_secundario_y_acaba_publicando(self):
        respuestas = [http_error(403, SECUNDARIO, {"Retry-After": "1"}), b'{"id": 1}']

        def falso_urlopen(request, timeout=None):
            siguiente = respuestas.pop(0)
            if isinstance(siguiente, HTTPError):
                raise siguiente
            return mock.MagicMock(
                __enter__=lambda self: mock.Mock(
                    read=lambda: siguiente, headers=mock.Mock(items=lambda: [])
                ),
                __exit__=lambda *a: False,
            )

        esperas: list[float] = []
        with mock.patch.object(reservas, "urlopen", falso_urlopen), mock.patch.object(
            reservas, "TOKEN", "x"
        ):
            payload, _ = reservas.api_json("POST", "/x", {"body": "y"}, dormir=esperas.append)

        self.assertEqual({"id": 1}, payload)
        self.assertEqual([1.0], esperas)

    def test_api_json_no_reintenta_un_403_de_permisos(self):
        llamadas = []

        def falso_urlopen(request, timeout=None):
            llamadas.append(request)
            raise http_error(403, '{"message":"Resource not accessible by integration"}')

        with mock.patch.object(reservas, "urlopen", falso_urlopen), mock.patch.object(
            reservas, "TOKEN", "x"
        ):
            with self.assertRaises(RuntimeError) as ctx:
                reservas.api_json("POST", "/x", {"body": "y"}, dormir=lambda _: None)

        self.assertEqual(1, len(llamadas))
        self.assertNotIsInstance(ctx.exception, reservas.ErrorTransitorio)


class LimpiezaLabelsAgenteTest(unittest.TestCase):
    def test_merge_limpia_solo_labels_de_coordinacion(self):
        reserva = reservas.Reserva(
            issue=70,
            agent="A",
            branch="feature/70",
            files="a.gd",
            goal="A",
            claimed_at=datetime(2026, 9, 28, tzinfo=UTC),
            last_activity=datetime(2026, 9, 28, tzinfo=UTC),
            lease_hours=48,
        )
        llamadas = []

        def api(method, path, payload=None, dormir=None):
            llamadas.append((method, path, payload))
            if method == "GET":
                return (
                    {
                        "labels": [
                            {"name": "area:siga"},
                            {"name": "prioridad:P1"},
                            {"name": "agent:auto"},
                            {"name": "agent:pr-open"},
                            {"name": "agent:needs-human"},
                        ]
                    },
                    {},
                )
            return ({}, {})

        pr = {
            "number": 700,
            "merged_at": "2026-09-28T12:00:00Z",
            "merge_commit_sha": "abc",
        }
        with mock.patch.object(reservas, "api_json", api):
            reservas.publicar_release(
                reserva,
                "merge-detectado-automaticamente",
                pr,
                dry_run=False,
            )

        self.assertEqual(
            [
                ("DELETE", f"/repos/{reservas.REPO}/issues/70/labels/agent%3Aauto", None),
                ("DELETE", f"/repos/{reservas.REPO}/issues/70/labels/agent%3Apr-open", None),
                ("DELETE", f"/repos/{reservas.REPO}/issues/70/labels/agent%3Aneeds-human", None),
            ],
            [llamada for llamada in llamadas if llamada[0] == "DELETE"],
        )
        self.assertFalse(any(method == "PATCH" for method, _, _ in llamadas))
        self.assertTrue(
            any(
                method == "POST"
                and path.endswith("/issues/182/comments")
                for method, path, _ in llamadas
            )
        )

    def test_cierre_sin_merge_no_limpia_labels(self):
        reserva = reservas.Reserva(
            issue=71,
            agent="A",
            branch="feature/71",
            files="a.gd",
            goal="A",
            claimed_at=datetime(2026, 9, 28, tzinfo=UTC),
            last_activity=datetime(2026, 9, 28, tzinfo=UTC),
            lease_hours=48,
        )
        llamadas = []

        def api(method, path, payload=None, dormir=None):
            llamadas.append((method, path, payload))
            return ({}, {})

        with mock.patch.object(reservas, "api_json", api):
            reservas.publicar_release(
                reserva,
                "PR-cerrado-sin-integrar",
                {"number": 701, "merged_at": None},
                dry_run=False,
            )

        self.assertFalse(any(method == "GET" for method, _, _ in llamadas))
        self.assertFalse(any(method == "PATCH" for method, _, _ in llamadas))

    def test_dry_run_no_modifica_labels(self):
        llamadas = []

        def api(method, path, payload=None, dormir=None):
            llamadas.append((method, path, payload))
            return (
                {
                    "labels": [
                        {"name": "area:siga"},
                        {"name": "agent:working"},
                    ]
                },
                {},
            )

        with mock.patch.object(reservas, "api_json", api):
            retiradas = reservas.limpiar_labels_agente(72, dry_run=True)

        self.assertEqual(["agent:working"], retiradas)
        self.assertEqual(
            [("GET", f"/repos/{reservas.REPO}/issues/72", None)],
            llamadas,
        )

    def test_delete_404_no_impide_el_resto(self):
        retiradas_esperadas = ["agent:auto", "agent:working"]
        llamadas = []
        borradas = []

        def api(method, path, payload=None, dormir=None):
            llamadas.append((method, path, payload))
            if method == "GET":
                return (
                    {"labels": [{"name": nombre} for nombre in retiradas_esperadas]},
                    {},
                )
            borradas.append(path)
            if path.endswith("/agent%3Aauto"):
                raise RuntimeError("GitHub API 404 en {path}: not found")
            return ({}, {})

        with mock.patch.object(reservas, "api_json", api):
            retiradas = reservas.limpiar_labels_agente(73, dry_run=False)

        self.assertEqual(retiradas_esperadas, retiradas)
        self.assertEqual(
            [
                f"/repos/{reservas.REPO}/issues/73/labels/agent%3Aauto",
                f"/repos/{reservas.REPO}/issues/73/labels/agent%3Aworking",
            ],
            borradas,
        )

    def test_fallo_al_limpiar_labels_no_impide_el_release(self):
        reserva = reservas.Reserva(
            issue=73,
            agent="A",
            branch="feature/73",
            files="a.gd",
            goal="A",
            claimed_at=datetime(2026, 9, 28, tzinfo=UTC),
            last_activity=datetime(2026, 9, 28, tzinfo=UTC),
            lease_hours=48,
        )
        llamadas = []

        def api(method, path, payload=None, dormir=None):
            llamadas.append((method, path))
            if method == "GET":
                raise RuntimeError("GitHub API 404 en issue transferido")
            return ({}, {})

        pr = {"number": 703, "merged_at": "2026-09-28T12:00:00Z", "merge_commit_sha": "abc"}
        with mock.patch.object(reservas, "api_json", api), mock.patch(
            "sys.stdout", new_callable=io.StringIO
        ) as salida:
            reservas.publicar_release(reserva, "merge-detectado-automaticamente", pr, dry_run=False)

        self.assertEqual("POST", llamadas[0][0])
        self.assertTrue(llamadas[0][1].endswith("/issues/182/comments"))
        self.assertTrue(reserva.released)
        self.assertIn("AVISO: no se pudieron limpiar labels de agente en #73", salida.getvalue())


class AislamientoDeFallosTest(unittest.TestCase):
    def test_un_fallo_al_liberar_no_impide_liberar_las_demas(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario("CLAIM issue=#10 agent=A branch=feature/10-a files=a.gd goal=A lease=1h", t0),
            comentario("CLAIM issue=#11 agent=B branch=feature/11-b files=b.gd goal=B lease=1h", t0),
        ]
        estado = reservas.reconstruir_reservas(comentarios)
        acciones = reservas.planificar_barrido(estado, t0 + timedelta(hours=2), lambda n: {})
        self.assertEqual(2, len(acciones))

        publicadas: list[int] = []

        def publicar(reserva, motivo, pr, dry_run):
            if reserva.issue == 10:
                raise reservas.ErrorTransitorio("rate limit")
            publicadas.append(reserva.issue)

        with mock.patch.object(reservas, "publicar_release", publicar), mock.patch.object(
            reservas, "obtener_comentarios", lambda: comentarios
        ), mock.patch.object(
            reservas, "obtener_pr_cerrada_de_rama", lambda rama: None
        ), mock.patch("sys.argv", ["x", "--sweep"]):
            codigo = reservas.main()

        self.assertEqual(1, codigo)
        self.assertEqual([11], publicadas)

    def test_un_pr_inconsultable_no_aborta_el_barrido_ni_libera_su_reserva(self):
        t0 = datetime(2026, 9, 15, 0, 0, tzinfo=UTC)
        comentarios = [
            comentario("CLAIM issue=#10 agent=A branch=feature/10-a files=a.gd goal=A lease=1h", t0),
            comentario("PR_READY issue=#10 pr=#500", t0),
            comentario("CLAIM issue=#11 agent=B branch=feature/11-b files=b.gd goal=B lease=1h", t0),
        ]
        estado = reservas.reconstruir_reservas(comentarios)

        def obtener_pr(numero: int) -> dict:
            raise reservas.ErrorTransitorio("rate limit")

        acciones = reservas.planificar_barrido(estado, t0 + timedelta(hours=2), obtener_pr)

        self.assertEqual([(11, "reserva-caducada")], [(a[0].issue, a[1]) for a in acciones])


def pr_cerrada(numero: int, rama: str, cerrada: datetime, merged: bool = True) -> dict:
    return {
        "number": numero,
        "state": "closed",
        "head": {"ref": rama},
        "closed_at": cerrada.isoformat().replace("+00:00", "Z"),
        "merged_at": cerrada.isoformat().replace("+00:00", "Z") if merged else None,
        "merge_commit_sha": "cafe" if merged else None,
    }


class RafagaDeMergesTest(unittest.TestCase):
    """#1512: GitHub cancela ejecuciones pendientes de reservas.yml en ráfagas."""

    t0 = datetime(2026, 9, 27, 14, 0, tzinfo=UTC)

    def test_claim_sin_pr_ready_se_libera_por_la_pr_cerrada_de_su_rama(self):
        estado = reservas.reconstruir_reservas([
            comentario("CLAIM issue=#20 agent=A branch=feature/20-a files=a.gd goal=A lease=48h", self.t0),
        ])
        acciones = reservas.planificar_barrido(
            estado,
            self.t0 + timedelta(hours=2),
            lambda n: {},
            pr_cerrada_de_rama=lambda rama: pr_cerrada(200, rama, self.t0 + timedelta(hours=1)),
        )
        self.assertEqual(
            [(20, "merge-detectado-automaticamente", 200)],
            [(r.issue, motivo, pr["number"]) for r, motivo, pr in acciones],
        )

    def test_rama_reutilizada_no_libera_un_claim_posterior_al_cierre(self):
        estado = reservas.reconstruir_reservas([
            comentario("CLAIM issue=#21 agent=A branch=feature/21-a files=a.gd goal=A lease=48h", self.t0),
        ])
        acciones = reservas.planificar_barrido(
            estado,
            self.t0 + timedelta(hours=2),
            lambda n: {},
            pr_cerrada_de_rama=lambda rama: pr_cerrada(201, rama, self.t0 - timedelta(hours=1)),
        )
        self.assertEqual([], acciones)

    def test_si_la_busqueda_por_rama_falla_solo_decide_la_lease(self):
        estado = reservas.reconstruir_reservas([
            comentario("CLAIM issue=#22 agent=A branch=feature/22-a files=a.gd goal=A lease=1h", self.t0),
        ])

        def falla(rama: str) -> dict | None:
            raise reservas.ErrorTransitorio("rate limit")

        acciones = reservas.planificar_barrido(
            estado, self.t0 + timedelta(hours=2), lambda n: {}, pr_cerrada_de_rama=falla
        )
        self.assertEqual([(22, "reserva-caducada")], [(a[0].issue, a[1]) for a in acciones])

    def test_solo_prs_cerradas_no_adelanta_leases_caducadas(self):
        estado = reservas.reconstruir_reservas([
            comentario("CLAIM issue=#23 agent=A branch=feature/23-a files=a.gd goal=A lease=1h", self.t0),
        ])
        acciones = reservas.planificar_barrido(
            estado,
            self.t0 + timedelta(hours=5),
            lambda n: {},
            pr_cerrada_de_rama=lambda rama: None,
            solo_prs_cerradas=True,
        )
        self.assertEqual([], acciones)

    def test_la_ultima_ejecucion_de_la_rafaga_libera_las_canceladas(self):
        # Tres merges seguidos: las ejecuciones de #301 y #302 se cancelaron y
        # solo corre la de #303. Debe liberar las tres, conservar la reserva con
        # PR abierta y no tocar la lease caducada, que es del barrido periódico.
        t0 = self.t0
        comentarios = [
            comentario("CLAIM issue=#31 agent=A branch=feature/31-a files=a.gd goal=A lease=48h", t0),
            comentario("PR_READY issue=#31 pr=#301 sha=abc", t0),
            comentario("CLAIM issue=#32 agent=B branch=feature/32-b files=b.gd goal=B lease=48h", t0),
            comentario("CLAIM issue=#33 agent=C branch=feature/33-c files=c.gd goal=C lease=48h", t0),
            comentario("PR_READY issue=#33 pr=#303 sha=abc", t0),
            comentario("CLAIM issue=#34 agent=D branch=feature/34-d files=d.gd goal=D lease=48h", t0),
            comentario("PR_READY issue=#34 pr=#304 sha=abc", t0),
            comentario("CLAIM issue=#35 agent=E branch=feature/35-e files=e.gd goal=E lease=1h", t0),
        ]
        merge = t0 + timedelta(hours=3)
        prs = {
            301: pr_cerrada(301, "feature/31-a", merge),
            303: pr_cerrada(303, "feature/33-c", merge),
            304: {"number": 304, "state": "open", "head": {"ref": "feature/34-d"}},
        }
        por_rama = {"feature/32-b": pr_cerrada(302, "feature/32-b", merge)}
        publicadas: list[tuple[int, str]] = []

        def publicar(reserva, motivo, pr, dry_run):
            publicadas.append((reserva.issue, motivo))
            reserva.released = True

        with mock.patch.object(reservas, "publicar_release", publicar), mock.patch.object(
            reservas, "obtener_comentarios", lambda: comentarios
        ), mock.patch.object(reservas, "obtener_pr", lambda n: prs[n]), mock.patch.object(
            reservas, "obtener_pr_cerrada_de_rama", lambda rama: por_rama.get(rama)
        ), mock.patch("sys.argv", ["x", "--pr", "303"]):
            codigo = reservas.main()

        self.assertEqual(0, codigo)
        self.assertEqual(
            [
                (33, "merge-detectado-automaticamente"),
                (31, "merge-detectado-automaticamente"),
                (32, "merge-detectado-automaticamente"),
            ],
            publicadas,
        )


if __name__ == "__main__":
    unittest.main()
