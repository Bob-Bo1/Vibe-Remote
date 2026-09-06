import os
import subprocess
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from ovb_rc003 import config, full_keys_setup


class FullKeysSetupTests(unittest.TestCase):
    def setUp(self):
        self.runtime = Path(r"C:\ProgramData\RemoteMicRC003\hid-tap\verified")
        self.config_path = Path(r"C:\RemoteMic\config.json")

    def test_enable_preserves_existing_config_and_opts_in(self):
        stored = {"gain_db": 10.0, "selected_device_profile": "xiaomi-rc003"}
        with (
            mock.patch.object(full_keys_setup, "runtime_directory", return_value=self.runtime),
            mock.patch.object(full_keys_setup, "_message_box", return_value=6),
            mock.patch.object(full_keys_setup, "_set_defender_exclusion", return_value=True) as defender,
            mock.patch.object(
                full_keys_setup.frida_hid_tap_runtime,
                "prepare_secure_runtime",
                return_value=self.runtime / "RemoteMicRC003HidTapFixed.dll",
            ),
            mock.patch.object(config, "config_path", return_value=self.config_path),
            mock.patch.object(config, "load_config", return_value=stored.copy()),
            mock.patch.object(config, "save_config") as save,
        ):
            result = full_keys_setup.enable_full_keys()

        self.assertTrue(result.ok)
        self.assertEqual(stored["selected_device_profile"], "xiaomi-rc003")
        saved = save.call_args.args[1]
        self.assertEqual(saved["selected_device_profile"], "xiaomi-rc003")
        self.assertTrue(saved["hid_report_tap_enabled"])
        defender.assert_called_once_with(self.runtime, enabled=True)

    def test_cancel_does_not_touch_defender_or_config(self):
        with (
            mock.patch.object(full_keys_setup, "runtime_directory", return_value=self.runtime),
            mock.patch.object(full_keys_setup, "_message_box", return_value=7),
            mock.patch.object(full_keys_setup, "_set_defender_exclusion") as defender,
            mock.patch.object(config, "save_config") as save,
        ):
            result = full_keys_setup.enable_full_keys()

        self.assertTrue(result.cancelled)
        defender.assert_not_called()
        save.assert_not_called()

    def test_enable_failure_removes_exclusion_added_by_this_run(self):
        with (
            mock.patch.object(full_keys_setup, "runtime_directory", return_value=self.runtime),
            mock.patch.object(full_keys_setup, "_set_defender_exclusion", side_effect=[True, None]) as defender,
            mock.patch.object(
                full_keys_setup.frida_hid_tap_runtime,
                "prepare_secure_runtime",
                side_effect=OSError("test extraction failure"),
            ),
        ):
            result = full_keys_setup.enable_full_keys(confirm=False)

        self.assertFalse(result.ok)
        self.assertEqual(
            defender.call_args_list,
            [
                mock.call(self.runtime, enabled=True),
                mock.call(self.runtime, enabled=False),
            ],
        )

    def test_disable_restores_config_and_removes_exact_directory(self):
        with (
            mock.patch.object(full_keys_setup, "runtime_directory", return_value=self.runtime),
            mock.patch.object(full_keys_setup, "_set_defender_exclusion") as defender,
            mock.patch.object(config, "config_path", return_value=self.config_path),
            mock.patch.object(config, "load_config", return_value={"hid_report_tap_enabled": True}),
            mock.patch.object(config, "save_config") as save,
        ):
            result = full_keys_setup.disable_full_keys()

        self.assertTrue(result.ok)
        self.assertFalse(save.call_args.args[1]["hid_report_tap_enabled"])
        defender.assert_called_once_with(self.runtime, enabled=False)

    @unittest.skipUnless(os.name == "nt", "PowerShell command shape is Windows-only")
    def test_defender_command_is_narrow_and_hash_directory_specific(self):
        completed = SimpleNamespace(returncode=0, stdout="ADDED\n")
        with mock.patch.object(subprocess, "run", return_value=completed) as run:
            added = full_keys_setup._set_defender_exclusion(self.runtime, enabled=True)

        self.assertTrue(added)
        command = run.call_args.args[0]
        self.assertEqual(command[0], "powershell.exe")
        script = command[-1]
        self.assertIn("Add-MpPreference -ExclusionPath", script)
        self.assertIn(str(self.runtime), script)
        self.assertNotIn("ExclusionProcess", script)
        self.assertNotIn("Set-MpPreference", script)


if __name__ == "__main__":
    unittest.main()
