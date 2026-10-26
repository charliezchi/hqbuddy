"""Interactive build selection with keyboard navigation and search."""

from . import config, scanner
from .term import interactive_pick

# pseudo-item at index 0: "let hqbuddy auto-select the newest version"
_LATEST = object()


def run_build_selector() -> "str | None":
    """
    Run interactive build selection with search.

    Returns:
        Selected build string, None for latest (or when cancelled).
    """
    cfg = config.load_config()
    all_versions = scanner.scan_all(cfg)
    if not all_versions:
        print("No HqFPGA versions found.")
        print("Tip: Use 'hqbuddy -cfg' to edit the scan roots in config.json.")
        return None

    current_build = cfg.get("selected_build")

    def _match(v, needle):
        return needle in v['build'].upper() or needle in v['semver'].upper()

    def row(v):
        if v is _LATEST:
            marker = ">" if current_build is None else " "
            return f"{marker} [latest]  Auto-select newest version"
        marker = ">" if v['build'] == current_build else " "
        return f"{marker} v{v['semver']}  (build {v['build']})"

    def match(item, needle):
        # the [latest] row stays visible only while some real version matches
        if item is _LATEST:
            return any(_match(v, needle) for v in all_versions)
        return _match(item, needle)

    start = 0 if current_build is None else 1
    idx = interactive_pick([_LATEST] + all_versions, row, match,
                           start_idx=start)
    if idx is None:
        return None
    if idx == 0:
        cfg['selected_build'] = None
        config.save_config(cfg)
        print("Selected: latest version (auto)")
        return None
    ver = all_versions[idx - 1]
    cfg['selected_build'] = ver['build']
    config.save_config(cfg)
    print(f"Selected: v{ver['semver']} (build {ver['build']})")
    return ver['build']
