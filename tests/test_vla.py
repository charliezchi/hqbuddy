import tempfile
import unittest
from pathlib import Path

from hqbuddy import vla


class EndpointTests(unittest.TestCase):
    entries = [
        {"inst": "top/u_a/u_leaf", "signal": "count", "suffix": "leaf[1]"},
        {"inst": "top/u_b/u_leaf", "signal": "count", "suffix": "leaf[1]_2"},
        {"inst": "top/u_b/u_leaf", "signal": "flag", "suffix": "leaf[1]_2"},
    ]

    def test_full_path_distinguishes_sibling_instances(self):
        selected = vla._select_endpoint("top/u_b/u_leaf/count[5:2]", self.entries,
                                        "top", "--la")
        self.assertEqual(selected["net"], "count__INS_leaf[1]_2__INS0")
        rtl = r"  wire [32'b111 : 32'b0] \count__INS_leaf[1]_2__INS0 ;"
        self.assertEqual(vla._endpoint_expr(rtl, selected, 4),
                         r"\count__INS_leaf[1]_2__INS0 [5:2]")

    def test_instance_shorthand_rejects_ambiguous_probes(self):
        with self.assertRaisesRegex(ValueError, "count.*flag"):
            vla._select_endpoint("top/u_b/u_leaf", self.entries, "top", "--la")

    def test_slice_must_fit_declared_bus(self):
        selected = vla._select_endpoint("top/u_a/u_leaf/count[8:5]", self.entries,
                                        "top", "--vio-in")
        rtl = r"  wire [7:0] \count__INS_leaf[1]__INS0 ;"
        with self.assertRaisesRegex(ValueError, r"\[7:0\]"):
            vla._endpoint_expr(rtl, selected, 4)

    def test_native_top_probe_can_be_an_unescaped_register(self):
        selected = {"inst": "top", "signal": "state", "net": "state__INS_top__INS0"}
        rtl = 'reg [7:0] state__INS_top__INS0/*synthesis HQ_IOREG="FALSE"*/;'
        self.assertEqual(vla._endpoint_expr(rtl, selected, 8), "state__INS_top__INS0")


class JointCaptureFrameTests(unittest.TestCase):
    def test_only_la_command_register_gets_zero_vio_field(self):
        pure = ("SIR 8 TDI (E0);\nSDR 32 TDI (00000000) TDO (0C30C7FD) MASK (FFFFFFFF);\n"
                "SIR 8 TDI (32);\nSDR 10 TDI (227);\n"
                "SDR 10 TDI (223) TDO (223) MASK (000);\n"
                "SIR 8 TDI (38);\nSDR 10 TDI (304);\n")
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "arm.svf"
            path.write_text(pure, encoding="ascii")
            vla._pad_la_command_frames(str(path), 5)
            self.assertEqual(path.read_text(encoding="ascii"),
                             pure.replace("SDR 10 TDI (227)", "SDR 15 TDI (44E0)")
                                 .replace("SDR 10 TDI (223) TDO (223) MASK (000)",
                                          "SDR 15 TDI (4460) TDO (4460) MASK (0000)"))

    def test_unrecognized_frame_is_rejected_before_file_changes(self):
        contents = "SIR 8 TDI (32);\nSDR 11 TDI (227);\n"
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "arm.svf"
            path.write_text(contents, encoding="ascii")
            with self.assertRaises(ValueError):
                vla._pad_la_command_frames(str(path), 5)
            self.assertEqual(path.read_text(encoding="ascii"), contents)
