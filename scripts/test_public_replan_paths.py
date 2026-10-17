"""Prevent public Autopilot replan comments leaking untracked paths."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from public_replan_paths import public_paths  # noqa: E402


class PublicReplanPathsTests(unittest.TestCase):
    def test_tracked_game_paths_preserve_planner_evidence(self):
        tracked = {"godot/guion/escena.gd", "scripts/test_camara.py"}
        self.assertEqual(
            public_paths(["godot/guion/escena.gd", "scripts/test_camara.py"], tracked),
            "godot/guion/escena.gd,scripts/test_camara.py",
        )

    def test_untracked_private_and_weird_paths_fail_closed(self):
        tracked = {"godot/escena.gd"}
        cases = [
            ["godot/escena.gd", "untracked_secret.txt"],
            ["/home/user/.config/private"],
            ["../private"],
            ["godot/escena.gd\nAPI_KEY=x"],
            ["godot/escena.gd,worker=qwen"],
            [],
            ["godot/escena.gd"] * 13,
            ["godot//escena.gd"],
        ]
        for case in cases:
            with self.subTest(case=repr(case)):
                self.assertIsNone(public_paths(case, tracked))

    def test_cli_allows_tracked_only_and_never_echoes_untracked_name(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "godot").mkdir()
            (root / "godot" / "escena.gd").write_text("extends Node\n")
            subprocess.run(["git", "-C", folder, "init", "-q"], check=True)
            subprocess.run(
                ["git", "-C", folder, "add", "godot/escena.gd"], check=True
            )
            guard = root / "guard.json"
            command = [
                sys.executable, str(ROOT / "scripts/public_replan_paths.py"),
                "--guard", str(guard), "--repo", folder,
            ]
            guard.write_text('{"outside":["godot/escena.gd"]}')
            good = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(good.returncode, 0)
            self.assertEqual(good.stdout.strip(), "godot/escena.gd")
            guard.write_text('{"outside":["private_runtime_gateway.json"]}')
            bad = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(bad.returncode, 2)
            self.assertNotIn("private_runtime_gateway.json", bad.stderr + bad.stdout)

    def test_workflow_preserves_replan_counter_and_no_route_leaks(self):
        s = (ROOT / ".github/workflows/agent-autopilot.yml").read_text()
        replan = s.split("- id: replan\n", 1)[1].split("- name: Validar diff y preflight", 1)[0]
        self.assertIn('startswith("AUTOPILOT_REPLAN ")', replan)
        self.assertIn('attempt=$attempt', replan)
        self.assertIn("scripts/public_replan_paths.py", replan)
        self.assertNotIn("provider=$PROVIDER observed_paths=$outside", replan)
        self.assertIn("agent:needs-human", replan)
        self.assertNotIn('$(grep \'^reason=\' "$GITHUB_OUTPUT"|cut -d= -f2-)', s)


if __name__ == "__main__":
    unittest.main()
