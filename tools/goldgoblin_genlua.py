# Erzeugt den Lua-Teil von Data/ProfessionRoutes.lua aus routes.json
# (siehe tools/goldgoblin_routes.py).
import json, sys
data = json.load(open(sys.argv[1], encoding='utf-8'))
PAGES = [  # Datei, skillLineID, Seitenname
    ('alchemie.html', 171, 'alchemie'), ('schmiedekunst.html', 164, 'schmiedekunst'),
    ('ingenieurskunst.html', 202, 'ingenieurskunst'), ('lederverarbeitung.html', 165, 'lederverarbeitung'),
    ('schneiderei.html', 197, 'schneiderei'), ('verzauberkunst.html', 333, 'verzauberkunst'),
    ('kochkunst.html', 185, 'kochkunst'), ('erste-hilfe.html', 129, 'erste-hilfe')]
def q(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'
out = []
for f, sid, slug in PAGES:
    out.append('    [%d] = { -- %s, Quelle: https://classic.goldgoblin.net/berufe/%s-forever/' % (sid, slug, slug))
    for s in data[f]:
        if not s['product']: continue
        a, b = s['range'].split('-')
        kind, pid, name = s['product']
        mats = ', '.join('{ %d, %s, %d, %s }' % (c, q(t), i, q(n)) for c, t, i, n in s['mats'])
        mt = (' matsText = %s,' % q(s['matsText'])) if s.get('matsText') else ''
        out.append('        { from = %s, to = %s, n = %s, kind = %s, id = %d, de = %s,%s%s mats = { %s } },' % (
            a, b, s['count'] or 'nil', q(kind), pid, q(name), ' alt = true,' if s['alt'] else '', mt, mats))
    out.append('    },')
print('\n'.join(out))
