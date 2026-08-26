"""Generate default-config .hqip files from IP meta XML.

The default-value resolution logic is ported from the standalone script
gen_default_hqip.py (ipcreator repository), which is itself a simplified
re-implementation of the IP Creator "create with default config" flow.
It supports the common meta XML features: cfg / cfg_group, values
type/default, values-level active_cond, Python-like expressions
referencing other cfgs. It does NOT support every corner of the
original engine (cfg-level cond, depends, rules/DRC, translations).

Also provides ipdepot scanning with device filtering (same matching
rules as IP Creator's main window) and an interactive IP picker.
"""

import configparser
import math
import msvcrt
import os
import re
import sys
import xml.etree.ElementTree as ET

from . import device as device_mod
from . import launcher

# ipdepot location inside an HqFpGA installation
_IPDEPOT_RELPATH = os.path.join('build', 'ipcreator', 'sup_files', 'ipdepot')


# ---------------------------------------------------------------
# meta XML parsing
# ---------------------------------------------------------------
class Cfg(object):
    def __init__(self, hier_name, hide, disp_only):
        self.hier_name = hier_name
        self.hide = hide
        self.disp_only = disp_only
        self.cond = None  # cfg-level active_cond
        # list of (active_cond, vtype, default, [value, ...], [desc, ...])
        self.values_blocks = []


def _strip_quotes(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        return s[1:-1]
    return s


def parse_meta_xml(xml_file):
    '''Returns (items, cfgs):
       items - ordered top-level list of ('cfg', name) / ('group', gname, [members])
       cfgs  - hier_name -> Cfg'''
    tree = ET.parse(xml_file)
    root = tree.getroot()

    items = []
    cfgs = {}

    def parse_cfg(elem, prefix):
        name = elem.get('name')
        hier = '%s.%s' % (prefix, name) if prefix else name
        cfg = Cfg(hier,
                  hide=(elem.get('hide') == '1'),
                  disp_only=(elem.get('disp_only') == '1'))
        cond_elem = elem.find('active_cond')
        if cond_elem is not None and cond_elem.text:
            cfg.cond = cond_elem.text.strip()
        for values in elem.findall('values'):
            cond_elem = values.find('active_cond')
            cond = cond_elem.text.strip() if (cond_elem is not None and cond_elem.text) else None
            vtype = values.get('type', 'enum')
            default = values.get('default')
            vals = [v.text.strip() for v in values.findall('value')
                    if v.text and v.text.strip()]
            descs = [re.sub(r'\{%.*?%\}', '', v.get('desc', '')).strip()
                     for v in values.findall('value')
                     if v.text and v.text.strip()]
            cfg.values_blocks.append((cond, vtype, default, vals, descs))
        cfgs[hier] = cfg
        return cfg

    for elem in root:
        if elem.tag == 'cfg':
            cfg = parse_cfg(elem, None)
            items.append(('cfg', cfg))
        elif elem.tag == 'cfg_group':
            gname = elem.get('name')
            members = []
            for sub in elem:
                if sub.tag == 'cfg':
                    members.append(parse_cfg(sub, gname))
                elif sub.tag == 'cfg_group':
                    # nested group: flatten with hierarchical names
                    for sub2 in sub:
                        if sub2.tag == 'cfg':
                            members.append(parse_cfg(sub2, '%s.%s' % (gname, sub.get('name'))))
            items.append(('group', gname, members))
        # other top-level elements (name/desc/port/...) are not needed

    return items, cfgs


# ---------------------------------------------------------------
# default value resolution (lazy, with dependency evaluation)
# ---------------------------------------------------------------
class Resolver(object):
    def __init__(self, cfgs):
        self.cfgs = cfgs
        self.cache = {}
        self.resolving = set()
        # longer names first so dotted names win over prefixes
        self.names = sorted(cfgs.keys(), key=len, reverse=True)

    def eval_expr(self, expr):
        '''Evaluate a meta expression with cfg names replaced by values.'''
        # meta-expression extension: X startswith "str"  ->  X.startswith("str")
        expr = re.sub(r'([a-zA-Z_][a-zA-Z0-9_\.]*)\s+startswith\s+(["\'])(.*?)\2',
                      r'\1.startswith("\3")', expr, flags=re.IGNORECASE)

        def repl(m):
            token = m.group(0)
            if token in self.cfgs:
                return repr(self.resolve(token))
            if token.endswith('.startswith'):
                base = token[:-len('.startswith')]
                if base in self.cfgs:
                    return repr(self.resolve(base)) + '.startswith'
                return "''.startswith"
            if token in ('and', 'or', 'not', 'if', 'else', 'in',
                         'log2', 'pow2', 'log', 'pow', 'int', 'float',
                         'double', 'startswith'):
                return token
            # unknown identifier (e.g. ip_device when no device is set):
            # the original engine has it in scope as an empty value
            return "''"
        # only replace identifiers OUTSIDE string literals
        parts = re.split(r'("[^"]*"|\'[^\']*\')', expr)
        for i in range(0, len(parts), 2):
            parts[i] = re.sub(r'[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*', repl, parts[i])
        py_expr = ''.join(parts)
        funcs = {
            'log2': lambda x: int(math.log2(x)),
            'pow2': lambda x: 2 ** int(x),
            'log': math.log,
            'pow': pow,
            'int': int,
            'float': float,
            'double': float,
            'true': True,
            'false': False,
        }
        return eval(py_expr, {'__builtins__': {}}, funcs)

    def convert(self, raw, vtype):
        raw = raw.strip()
        if vtype == 'bool':
            return raw.lower() in ('true', '1')
        if vtype == 'int':
            try:
                return int(raw)
            except ValueError:
                return int(self.eval_expr(raw))
        # enum / text / file: keep as string, but evaluate if it is an expression
        if re.search(r'[A-Za-z_]\w*\.[A-Za-z_]\w*', raw) or re.search(r'[+\-*/()%]', raw):
            try:
                v = self.eval_expr(raw)
                return v
            except Exception:
                pass
        return _strip_quotes(raw)

    def resolve(self, hier_name):
        if hier_name in self.cache:
            return self.cache[hier_name]
        if hier_name in self.resolving:
            raise Exception('circular dependency on cfg "%s"' % hier_name)
        cfg = self.cfgs[hier_name]
        self.resolving.add(hier_name)
        try:
            val = self._resolve_cfg(cfg)
            self.cache[hier_name] = val
            return val
        finally:
            self.resolving.discard(hier_name)

    def _resolve_cfg(self, cfg):
        # NOTE: cfg-level active_cond is intentionally ignored: the original
        # engine still assigns the default value to an inactive cfg (e.g. pll
        # clkos.cas=0 while clkos.enable=FALSE).
        first_fallback = None
        for cond, vtype, default, vals, descs in cfg.values_blocks:
            if first_fallback is None and vals:
                first_fallback = (vtype, vals[0])
            if cond:
                try:
                    if not self.eval_expr(cond):
                        continue
                except Exception:
                    continue
            # first values block whose condition holds
            if default is not None:
                dval = default.strip()
                if vals:
                    matched = None
                    # the engine evaluates the default and the values as
                    # expressions and compares the results ('NORM' matches
                    # "NORM"; an unquoted identifier fails eval and is invalid)
                    try:
                        d_ev = self.eval_expr(dval)
                        for v in vals:
                            try:
                                if self.eval_expr(v) == d_ev:
                                    matched = v
                                    break
                            except Exception:
                                if v.strip() == dval:
                                    matched = v
                                    break
                    except Exception:
                        pass
                    if matched is None and dval in vals:
                        matched = dval
                    if matched is None:
                        # enum default may be given as a value description, e.g. "NONE"
                        for i, desc in enumerate(descs):
                            if desc and desc.lower() == dval.lower():
                                matched = vals[i]
                                break
                    # invalid default: fall back to the first valid value
                    dval = matched if matched is not None else vals[0]
                return self.convert(dval, vtype)
            if vals:
                return self.convert(vals[0], vtype)
        # no condition matched: use first valid value of the first block
        if first_fallback is not None:
            return self.convert(first_fallback[1], first_fallback[0])
        # nothing resolvable (e.g. empty file values): empty string
        return ''


def value_to_str(v):
    if v is None:
        return ''
    if isinstance(v, bool):
        return 'TRUE' if v else 'FALSE'
    return str(v)


# ---------------------------------------------------------------
# .hqip generation (mirrors MetaInfo.get_ini_content / output_ini /
# append_outinfo_to_ini / append_ipinfo_to_ini)
# ---------------------------------------------------------------
def get_ini_content(items, resolver):
    s = ''
    prv_was_cfg = False
    for item in items:
        if item[0] == 'cfg':
            cfg = item[1]
            if cfg.hide:
                continue  # hidden cfgs do not affect the prev-item state
            if not cfg.disp_only:
                s += '%s=%s\n' % (cfg.hier_name, value_to_str(resolver.resolve(cfg.hier_name)))
            prv_was_cfg = True
        else:  # group
            # NOTE: hidden cfgs inside a group ARE written (the original
            # get_ini_content_aux only skips display_only for group members)
            members = item[2]
            if prv_was_cfg and members:
                s += '\n'
            body = ''
            for cfg in members:
                if not cfg.disp_only:
                    body += '%s=%s\n' % (cfg.hier_name, value_to_str(resolver.resolve(cfg.hier_name)))
            if body:
                s += body + '\n'
            prv_was_cfg = False
    return s


def load_internal_ini(xml_file):
    '''Load name=value pairs from the optional <xmlroot>.ii file ([General] section).'''
    ii_file = os.path.splitext(xml_file)[0] + '.ii'
    if not (os.path.exists(ii_file) and os.path.isfile(ii_file)):
        return []
    cp = configparser.ConfigParser()
    cp.optionxform = str
    cp.read(ii_file)
    pairs = []
    for sec in cp.sections():
        for nm, val in cp.items(sec):
            pairs.append((nm, val))
    return pairs


def gen_default_hqip(meta_file, hqip_file, device):
    meta_file = os.path.abspath(meta_file)
    hqip_file = os.path.abspath(hqip_file)

    items, cfgs = parse_meta_xml(meta_file)
    resolver = Resolver(cfgs)
    ini_content = get_ini_content(items, resolver)
    ii_pairs = load_internal_ini(meta_file)

    module_name = os.path.splitext(os.path.basename(hqip_file))[0]

    os.makedirs(os.path.dirname(hqip_file), exist_ok=True)
    with open(hqip_file, 'w') as f:
        # [General]
        print('[General]', file=f)
        if ii_pairs:
            print(';internal ini values', file=f)
            print(';-----------------------------', file=f)
            for nm, val in ii_pairs:
                print('%s=%s' % (nm, val), file=f)
            print(';-----------------------------', file=f)
        print(ini_content, file=f)

        # [File]
        print('[File]', file=f)
        print('output_module=%s' % module_name, file=f)

        # [IP]
        print('', file=f)
        print('[IP]', file=f)
        print('#! device from HqFpga project', file=f)
        print('device=%s' % device, file=f)
        print('meta_file=%s' % meta_file.replace('\\', '/'), file=f)
        print('', file=f)

    return hqip_file


# ---------------------------------------------------------------
# ipdepot scanning with device filtering (IP Creator matching rules)
# ---------------------------------------------------------------
def _parse_ip_head(xml_file):
    """Lightweight parse of an IP meta XML: only top-level head fields."""
    try:
        root = ET.parse(xml_file).getroot()
    except ET.ParseError:
        return None

    def _text(tag):
        elem = root.find(tag)
        return elem.text.strip() if elem is not None and elem.text else ''

    name = _text('name')
    if not name:
        return None
    desc = re.sub(r'\{%.*?%\}', '', _text('desc')).strip()
    categories = [c.text.strip() for c in root.findall('./categories/category')
                  if c.text and c.text.strip()]
    return {
        'xml': xml_file,
        'name': name,
        'desc': desc,
        'categories': categories,
        'devices': _text('devices'),
        'exclusive_devices': _text('exclusive_devices'),
        'variant': os.path.basename(os.path.dirname(xml_file)),
    }


def _family_tokens(device: str) -> set:
    """Family tokens for IP matching. Prefers dv_list.xml lookup
    (robust), falls back to the IP Creator prefix rules."""
    tokens = set()
    fam = device_mod.get_family_for_device(device)
    if fam:
        tokens.add(fam.upper())
    ud = device.upper()
    if re.match(r'SL2[A-Z]*\-', ud):
        tokens.add('SEALION')
    if ud == 'SEAL' or re.match(r'SA5[A-Z]*\-', ud) or re.match(r'SCM905[A-Z]*\-', ud):
        tokens.add('SEAL')
    return tokens


def scan_supported_ips(ipdepot_dir: str, device: str) -> list:
    """List IP meta XMLs in ipdepot supporting the given device part."""
    dev = device.upper()
    fam_tokens = _family_tokens(device)
    hits = []
    for dirpath, _dirnames, filenames in os.walk(ipdepot_dir):
        for fn in sorted(filenames):
            if not fn.lower().endswith('.xml'):
                continue
            info = _parse_ip_head(os.path.join(dirpath, fn))
            if not info:
                continue
            ok = False
            for t in info['exclusive_devices'].split():
                if dev.startswith(t.upper()):
                    ok = True
                    break
            if not ok:
                for t in info['devices'].split():
                    if dev.startswith(t.upper()) or t.upper() in fam_tokens:
                        ok = True
                        break
            if ok:
                hits.append(info)
    hits.sort(key=lambda h: (h['categories'][0] if h['categories'] else '', h['name']))
    return hits


# ---------------------------------------------------------------
# interactive IP picker (same UX as -build_sel / -set_device)
# ---------------------------------------------------------------
def _clear_lines(n: int):
    for _ in range(n):
        sys.stdout.write('\033[F\033[K')
    sys.stdout.flush()


def _matches(info: dict, search: str) -> bool:
    s = search.upper()
    return (s in info['name'].upper()
            or s in info['variant'].upper()
            or s in info['desc'].upper())


def _draw_ip_menu(items: list, selected_idx: int, search: str) -> int:
    lines = 0
    print(f"Type to search: {search}")
    lines += 1

    total = len(items)
    start = max(0, selected_idx - 10)
    end = min(total, start + 20)
    if end - start < 20 and start > 0:
        start = max(0, end - 20)

    for i in range(start, end):
        cursor = " ▶" if selected_idx == i else "  "
        info = items[i]
        desc = f"  {info['desc']}" if info['desc'] else ""
        print(f"{cursor} {info['name']}  ({info['variant']}){desc}")
        lines += 1

    if total > end:
        print(f"  ... and {total - end} more")
        lines += 1
    if total == 0:
        print("  (no matches)")
        lines += 1

    sys.stdout.flush()
    return lines


def pick_ip_interactive(items: list) -> dict | None:
    """Interactive IP selection with fuzzy search over name/variant/desc."""
    filtered = list(items)
    search = ""
    selected_idx = 0

    lines_printed = _draw_ip_menu(filtered, selected_idx, search)

    while True:
        key = msvcrt.getch()

        if key == b'\xe0':  # Arrow keys
            key = msvcrt.getch()
            if key == b'H':  # Up
                selected_idx = max(0, selected_idx - 1)
            elif key == b'P':  # Down
                selected_idx = min(len(filtered) - 1, selected_idx + 1)
            _clear_lines(lines_printed)
            lines_printed = _draw_ip_menu(filtered, selected_idx, search)

        elif key == b'\r':  # Enter
            _clear_lines(lines_printed)
            if 0 <= selected_idx < len(filtered):
                return filtered[selected_idx]
            return None

        elif key == b'\x08':  # Backspace
            if search:
                search = search[:-1]
                filtered = [it for it in items if _matches(it, search)]
                selected_idx = min(selected_idx, len(filtered) - 1)
                if selected_idx < 0:
                    selected_idx = 0
            _clear_lines(lines_printed)
            lines_printed = _draw_ip_menu(filtered, selected_idx, search)

        elif key == b'\x1b':  # Esc
            _clear_lines(lines_printed)
            return None

        elif key == b'\x03':  # Ctrl+C
            print("")
            return None

        else:  # Regular character (for search)
            try:
                ch = key.decode('utf-8')
                if ch.isprintable():
                    search += ch
                    filtered = [it for it in items if _matches(it, search)]
                    selected_idx = min(selected_idx, len(filtered) - 1)
                    if selected_idx < 0:
                        selected_idx = 0
                _clear_lines(lines_printed)
                lines_printed = _draw_ip_menu(filtered, selected_idx, search)
            except UnicodeDecodeError:
                pass


# ---------------------------------------------------------------
# command entry
# ---------------------------------------------------------------
def _find_hqprj() -> str | None:
    import glob
    matches = glob.glob("*.hqprj")
    return matches[0] if matches else None


def _resolve_device(device_arg: str | None) -> str:
    if device_arg:
        return device_arg
    hqprj = _find_hqprj()
    if hqprj:
        return device_mod.get_device(hqprj)
    print("Error: cannot determine target device.")
    print("       Run inside a project directory (with .hqprj) or pass -device <part>.")
    sys.exit(1)


def _default_output(info: dict) -> str:
    """Default output path: ipcore_dir/<IP_NAME>/xsIP_<IP_NAME>.hqip"""
    name = info['name']
    return os.path.join(os.getcwd(), 'ipcore_dir', name, f"xsIP_{name}.hqip")


def run_gen_hqip(args: list) -> None:
    """Generate a default-config .hqip from an IP meta XML.

    Usage: hqbuddy -gen_hqip [<meta.xml>] [-device <part>]
    Without a meta XML, lists IPs supporting the current device and
    lets the user pick one interactively.
    """
    xml_arg = None
    device_arg = None
    i = 0
    while i < len(args):
        a = args[i]
        if a == '-device' and i + 1 < len(args):
            device_arg = args[i + 1]
            i += 2
        elif a.startswith('-'):
            print(f"Error: unknown option: {a}")
            sys.exit(1)
        elif xml_arg is None:
            xml_arg = a
            i += 1
        else:
            print(f"Error: unexpected argument: {a}")
            sys.exit(1)

    device = _resolve_device(device_arg)

    if xml_arg:
        # Explicit meta XML: skip scanning and interaction
        if not os.path.isfile(xml_arg):
            print(f"Error: meta XML not found: {xml_arg}")
            sys.exit(1)
        info = _parse_ip_head(xml_arg)
        name = info['name'] if info else os.path.splitext(os.path.basename(xml_arg))[0]
        out = os.path.join(os.getcwd(), 'ipcore_dir', name, f"xsIP_{name}.hqip")
        gen_default_hqip(xml_arg, out, device)
        print(f"[OK] Generated: {out} (device: {device})")
    else:
        version = launcher.resolve_hqfpga_version()
        if not version:
            print("Error: no HqFPGA versions found.")
            print("Tip: Use 'hqbuddy -cfg' to edit the scan roots in config.json.")
            sys.exit(1)
        ipdepot = os.path.join(version['path'], _IPDEPOT_RELPATH)
        if not os.path.isdir(ipdepot):
            print(f"Error: ipdepot not found: {ipdepot}")
            sys.exit(1)

        items = scan_supported_ips(ipdepot, device)
        if not items:
            print(f"No IPs found supporting device {device}.")
            sys.exit(1)
        print(f"Device: {device}  ({len(items)} IPs available)")

        chosen = pick_ip_interactive(items)
        if not chosen:
            print("Cancelled.")
            return
        out = _default_output(chosen)
        gen_default_hqip(chosen['xml'], out, device)
        print(f"Selected: {chosen['name']} ({chosen['variant']})")
        print(f"[OK] Generated: {out} (device: {device})")

    print(f"Tip: run 'hqbuddy -ipgen' to generate the IP netlist.")
