"""Count connected shells in a binary STL. Usage: python count_shells.py part.stl

Hardened 2026-08-12 after two system crashes: the original version trusted the
binary header's triangle count on files that were actually ASCII STL (OpenSCAD
2021.01's CLI default), computed a garbage count from text bytes, and committed
~220 GB before Windows fell over. Every input is now validated BEFORE any
allocation, and allocations are bounded by construction.
"""
import os, struct, sys
from array import array

MAX_TRIS = 2_000_000  # ~100 MB file; two orders of magnitude above any part here


def fail(msg):
    sys.exit(f"ERROR: {msg}")


def shells(path):
    size = os.path.getsize(path)
    if size < 84:
        fail(f"{path}: {size} bytes - too small to be a binary STL")
    with open(path, "rb") as f:
        head = f.read(80)
        n = struct.unpack("<I", f.read(4))[0]
        if size != 84 + 50 * n:
            kind = ("ASCII STL - export with --export-format binstl"
                    if head.lstrip().startswith(b"solid")
                    else "truncated or corrupt binary STL")
            fail(f"{path}: header claims {n} triangles (needs {84 + 50 * n} "
                 f"bytes) but file is {size} bytes - {kind}")
        if n > MAX_TRIS:
            fail(f"{path}: {n} triangles exceeds sanity cap {MAX_TRIS}")
        parent = array("i", range(3 * n))

        def find(a):
            while parent[a] != a:
                parent[a] = parent[parent[a]]
                a = parent[a]
            return a

        seen = {}
        zmin = None
        vertex_z = {}
        for i in range(n):
            data = f.read(50)
            tri = []
            for k in range(3):
                v = struct.unpack_from("<3f", data, 12 + k * 12)
                if zmin is None or v[2] < zmin:
                    zmin = v[2]
                key = tuple(round(c, 4) for c in v)
                idx = seen.setdefault(key, 3 * i + k)
                vertex_z[idx] = v[2]
                tri.append(idx)
            for a in tri[1:]:
                ra, rb = find(tri[0]), find(a)
                if ra != rb:
                    parent[rb] = ra

        # per-shell zmin: after all unions are resolved, group each canonical
        # vertex by its root and take the minimum z seen in that root's shell
        shell_zmin = {}
        for idx in seen.values():
            root = find(idx)
            z = vertex_z[idx]
            if root not in shell_zmin or z < shell_zmin[root]:
                shell_zmin[root] = z
        worst_shell_zmin = max(shell_zmin.values())

        return (len({find(i) for i in seen.values()}), zmin, worst_shell_zmin)


count, zmin, worst_shell_zmin = shells(sys.argv[1])
print(f"shells={count}")
print(f"zmin={zmin:.3f}")
print(f"worst_shell_zmin={worst_shell_zmin:.3f}")
