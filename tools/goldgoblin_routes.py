# Liest die Skill-Routen aus gespeicherten goldgoblin-Berufsseiten (HTML).
# Aufruf: python3 -I tools/goldgoblin_routes.py <ordner>/alchemie.html ... -> routes.json
# Danach: python3 -I tools/goldgoblin_genlua.py routes.json > Ausschnitt für Data/ProfessionRoutes.lua
# Die HTML-Seiten vorher selbst herunterladen (z. B. mit curl) und in einen
# eigenen Ordner legen; die Skripte nur auf dieser Kopie laufen lassen.
# Allgemeiner Auswerter für goldgoblin-Skillrouten (alle Seitenvarianten).
import re, sys, json, html as H
START = re.compile(r'<div class="(?:wp-block-columns )?gg-skillguide([^"]*)"|<div class="gg-ck__step([^"]*)"')
A = re.compile(r'<a [^>]*href="https://www\.wowhead\.com/forever/de/(item|spell)=(\d+)[^"]*"[^>]*>(?:<span>)?([^<]+)')
def clean(s): return H.unescape(re.sub(r'<[^>]+>', ' ', s)).replace('\xa0',' ')
def inside_details(h, pos):
    # offen, wenn mehr <details als </details vor pos (nur gg-fa__more = Alternativen)
    opened = [m.start() for m in re.finditer(r'<details class="gg-fa__more"', h[:pos])]
    closed = [m.start() for m in re.finditer(r'</details>', h[:pos])]
    # grob: letzte gg-fa__more-Öffnung nach der letzten passenden Schließung?
    if not opened: return False
    last_open = opened[-1]
    # zähle details-Öffnungen/Schließungen nach last_open
    seg = h[last_open:pos]
    return seg.count('<details') > seg.count('</details>')
def parse(path):
    h = open(path, encoding='utf-8').read()
    starts = [m for m in START.finditer(h)]
    out = []
    for k, m in enumerate(starts):
        end = starts[k+1].start() if k+1 < len(starts) else m.start()+4000
        block = h[m.start():end]
        block = re.split(r'<details class="gg-(?:fa|fh|ck)__(?:recipe-dropdown|more)"', block)[0]
        rng = re.search(r'class="(?:wp-block-column )?range"[^>]*>(?:<p>)?([^<]+)|class="gg-ck__range">([^<]+)', block)
        if not rng: continue
        r = (rng.group(1) or rng.group(2)).strip().replace('–','-')
        head = re.search(r'<(strong|b)>(.*?)</\1>', block, re.S)
        if not head: continue
        hs = head.group(2)
        prod = A.search(hs)
        cnt = re.search(r'(\d+)\s*×', clean(hs))
        rest = block[head.end():]
        # Hinweis-Absätze (Alternativen, Notizen) entfernen
        rest = re.sub(r'<p class="gg-f[ah]__(?:row-note|origin)"[^>]*>(?!\s*Material).*?</p>', '', rest, flags=re.S)
        # Material: Rest des Kopf-Absatzes + nächster Absatz mit "Material" bzw. <small> (Kochkunst)
        first = rest.split('</p>')[0]
        extra = re.search(r'<p[^>]*>\s*Material[^<]*?:.*?</p>|<small>.*?</small>', rest, re.S)
        rest = first + (extra.group(0) if extra else '')
        mats = []
        for mm in re.finditer(r'(\d+)\s*×\s*' + A.pattern, rest):
            mats.append([int(mm.group(1)), mm.group(2), int(mm.group(3)), H.unescape(mm.group(4)).strip()])
        matsText = None
        if not mats:
            t = clean(rest)
            t = re.sub(r'^\s*·\s*', '', t.strip())
            t = re.sub(r'^Material[^:]*:\s*', '', t.strip())
            t = re.sub(r'\s+', ' ', t).strip(' ·')
            matsText = t or None
        out.append({'matsText': matsText, 'range': r, 'color': (m.group(1) or m.group(2) or '').strip(),
                    'alt': inside_details(h, m.start()),
                    'count': int(cnt.group(1)) if cnt else None,
                    'product': prod and [prod.group(1), int(prod.group(2)), H.unescape(prod.group(3)).strip()],
                    'mats': mats})
    return out
if __name__ == '__main__':
    res = {}
    for p in sys.argv[1:]:
        steps = parse(p); res[p] = steps
        print('==', p, len(steps), 'davon Alternativen', sum(s['alt'] for s in steps))
        for s in steps:
            pr = s['product']
            print('  %s%-8s %-7s %4s× %s%s %s | %s' % ('ALT ' if s['alt'] else '', s['range'], s['color'], s['count'], pr and pr[0][0] if pr else '-', pr and pr[1] if pr else '', pr and pr[2][:34] if pr else '', ', '.join('%dx%s' % (c, n) for c, t, i, n in s['mats'])[:80]))
    json.dump(res, open('routes.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
