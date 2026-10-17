#!/usr/bin/env python3
"""Pruebas para las funciones de gestión de tiempo y métricas en scripts/ci_brain.py."""

import unittest
from datetime import datetime, timezone, timedelta

from scripts.ci_brain import utc_now, iso, parse_time, duration_seconds, percentile_95


class TestCIBrainTiempo(unittest.TestCase):
    """Pruebas unitarias para utc_now, iso, parse_time, duration_seconds y percentile_95."""

    def test_utc_now(self) -> None:
        now = utc_now()
        self.assertIsInstance(now, datetime)
        self.assertEqual(now.tzinfo, timezone.utc)

    def test_iso(self) -> None:
        dt_utc = datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc)
        self.assertEqual(iso(dt_utc), "2026-10-17T12:00:00Z")

        dt_offset = datetime(2026, 10, 17, 14, 0, 0, tzinfo=timezone(timedelta(hours=2)))
        self.assertEqual(iso(dt_offset), "2026-10-17T12:00:00Z")

    def test_parse_time(self) -> None:
        parsed_z = parse_time("2026-10-17T12:00:00Z")
        self.assertEqual(parsed_z, datetime(2026, 10, 17, 12, 0, 0, tzinfo=timezone.utc))

        parsed_offset = parse_time("2026-10-17T14:00:00+02:00")
        expected_offset = datetime(2026, 10, 17, 14, 0, 0, tzinfo=timezone(timedelta(hours=2)))
        self.assertEqual(parsed_offset, expected_offset)

        self.assertIsNone(parse_time(None))
        self.assertIsNone(parse_time(""))

        with self.assertRaises(ValueError):
            parse_time("basura")

    def test_duration_seconds(self) -> None:
        start = "2026-10-17T12:00:00Z"
        end = "2026-10-17T12:05:00Z"
        self.assertEqual(duration_seconds(start, end), 300.0)

        # Duración negativa: end es anterior a start -> debe acotarse a 0.0 mediante max(0.0, ...)
        self.assertEqual(duration_seconds(end, start), 0.0)

        # Extremos ausentes
        self.assertIsNone(duration_seconds(None, end))
        self.assertIsNone(duration_seconds(start, None))
        self.assertIsNone(duration_seconds(None, None))

    def test_percentile_95(self) -> None:
        # 0 valores
        self.assertIsNone(percentile_95([]))

        # 1 valor
        self.assertEqual(percentile_95([10.0]), 10.0)

        # 2 valores
        # index = round(0.95 * 1) = round(0.95) = 1 -> values[1] = 20.0
        self.assertEqual(percentile_95([10.0, 20.0]), 20.0)

        # 100 valores (0.0 a 99.0)
        # len = 100, index = round(0.95 * 99) = round(94.05) = 94 -> values[94] = 94.0
        values_100 = [float(x) for x in range(100)]
        self.assertEqual(percentile_95(values_100), 94.0)


if __name__ == "__main__":
    unittest.main()
