#!/usr/bin/env python3
"""Xera un sitio estático, sen conexión, coas documentacións de DevDocs indicadas.

Uso: build-site.py SLUG...   (por exemplo: build-site.py html http)

Descarga de documents.devdocs.io o índice (index.json) e as páxinas (db.json) de
cada documentación, o contido de MDN Web Docs xa preparado por DevDocs, e garda
cada páxina como HTML na súa ruta. As ligazóns internas son relativas e sen
.html, como en DevDocs: nginx serve /http/guides/cookies desde
http/guides/cookies.html. Non inclúe a aplicación de DevDocs, que só funciona
servida desde devdocs.io. A busca é de Pagefind, que se indexa despois.
"""
import html
import json
import os
import pathlib
import re
import sys
import urllib.request

CATALOG_URL = 'https://devdocs.io/docs/docs.json'
DATA_URL = 'https://documents.devdocs.io/{slug}/{name}'
SITE = pathlib.Path(os.environ.get('SITE_DIR', '/site'))
MDN_ATTRIBUTION = ('&copy; 2005&ndash;2025 MDN contributors.<br>'
                   'Licensed under the Creative Commons Attribution-ShareAlike License v2.5 or later.')

PAGE = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<link rel="stylesheet" href="/style.css">
{head}</head>
<body>
<header class="site-header">
  <a class="site-home" href="/">Web reference</a>
  {crumb}
  <a class="site-search" href="/">Search</a>
</header>
<main{main_attrs}>
{filter}{body}
</main>
<footer class="site-footer">Offline copy for DAW of the {docs} documentation from MDN Web Docs, prepared by DevDocs.</footer>
</body>
</html>
'''

STYLE = '''*{box-sizing:border-box}
body{margin:0;font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:#1b1b1b;background:#fff}
.site-header{display:flex;gap:1rem;align-items:center;padding:.6rem 1.5rem;background:#1b1b1b;color:#fff}
.site-header a{color:#fff;text-decoration:none}
.site-home{font-weight:700}
.site-search{margin-left:auto}
main{max-width:960px;margin:0 auto;padding:1rem 1.5rem 3rem}
.site-footer{max-width:960px;margin:0 auto;padding:1rem 1.5rem;color:#666;font-size:.85rem;border-top:1px solid #ddd}
a{color:#0069c2}
h1,h2,h3{line-height:1.25}
pre,code{font-family:ui-monospace,"Cascadia Code",Consolas,monospace;font-size:.9em}
pre{background:#f4f4f4;padding:.8rem 1rem;overflow:auto;border-radius:4px}
:not(pre)>code{background:#f4f4f4;padding:.1em .3em;border-radius:3px}
table{border-collapse:collapse;margin:1rem 0;display:block;overflow:auto}
th,td{border:1px solid #ddd;padding:.35rem .6rem;text-align:left;vertical-align:top}
th{background:#f4f4f4}
details.baseline-indicator{border:1px solid #ddd;border-radius:4px;padding:.3rem .8rem;margin:1rem 0}
.bc-supports-yes{background:#e6f4ea}
.bc-supports-no{background:#fce8e6}
.notecard,.note,.warning{border-left:4px solid #0069c2;background:#f0f6fc;padding:.5rem 1rem;margin:1rem 0}
.warning{border-color:#d93025;background:#fce8e6}
._attribution{margin-top:2rem;color:#666;font-size:.85rem}
.entries ul{columns:2 18rem;padding-left:1.2rem}
.docs li{margin:.4rem 0}
'''


def fetch_json(url):
    # devdocs.io rexeita (403) o User-Agent por defecto de urllib.
    request = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (compatible; daw-doc build)'})
    with urllib.request.urlopen(request, timeout=300) as response:
        return json.load(response)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')


def page(title, body, docs, crumb='', indexed=True, doc=None, head=''):
    return PAGE.format(
        title=html.escape(title), head=head, crumb=crumb, body=body, docs=docs,
        main_attrs=' data-pagefind-body' if indexed else '',
        filter=f'<span hidden data-pagefind-filter="doc">{html.escape(doc)}</span>\n' if doc else '')


# DevDocs pon o seu título antes do de MDN: queda só o de MDN.
DOUBLE_TITLE = re.compile(r'^\s*<h1>[^<]*</h1>\s*(?:<mdn-survey></mdn-survey>\s*)?(?=<h1>)')


def clean(content):
    return DOUBLE_TITLE.sub('', content).replace('<mdn-survey></mdn-survey>', '')


def check_path(slug, path):
    parts = path.split('/')
    if not path or path.startswith('/') or '\\' in path or '..' in parts or '' in parts:
        sys.exit(f'Unexpected page path in {slug}: {path!r}')


def build(slug, meta, docs):
    index = fetch_json(DATA_URL.format(slug=slug, name='index.json'))
    db = fetch_json(DATA_URL.format(slug=slug, name='db.json'))
    name = meta['name'] + (f" {meta['version']}" if meta.get('version') else '')
    crumb = f'<span>/</span> <a href="/{slug}/">{html.escape(name)}</a>'
    titles = {e['path']: e['name'] for e in index['entries'] if '#' not in e['path']}
    for path, content in db.items():
        if path == 'index':
            continue
        check_path(slug, path)
        write(SITE / slug / f'{path}.html',
              page(f"{titles.get(path, path)} - {name}", clean(content), docs, crumb, doc=name))
    # Portada da documentación: a de MDN e, despois, todas as entradas por tipo.
    groups = {t['name']: [] for t in index['types']}
    for entry in index['entries']:
        groups.setdefault(entry['type'], []).append(entry)
    listing = ['<section class="entries"><h2>All entries</h2>']
    for group, entries in groups.items():
        if not entries:
            continue
        listing.append(f'<h3>{html.escape(group)}</h3><ul>')
        listing += [f'<li><a href="{html.escape(e["path"])}">{html.escape(e["name"])}</a></li>' for e in entries]
        listing.append('</ul>')
    listing.append('</section>')
    write(SITE / slug / 'index.html', page(name, clean(db.get('index', f'<h1>{html.escape(name)}</h1>')) + '\n'.join(listing),
                                           docs, crumb, doc=name))
    print(f'{slug}: {len(db)} pages, {len(index["entries"])} entries')
    return name, meta


def main(slugs):
    if not slugs:
        sys.exit('Usage: build-site.py SLUG...')
    catalog = {d['slug']: d for d in fetch_json(CATALOG_URL)}
    unknown = [s for s in slugs if s not in catalog]
    if unknown:
        sys.exit(f'Unknown DevDocs documentation: {" ".join(unknown)}')
    names = ', '.join(catalog[s]['name'] for s in slugs)
    built = [(slug, *build(slug, catalog[slug], names)) for slug in slugs]
    items = []
    for slug, name, meta in built:
        attribution = meta.get('attribution') or MDN_ATTRIBUTION
        items.append(f'<li><a href="/{slug}/">{html.escape(name)}</a>: {attribution}</li>')
    search = ('<div id="search"></div>\n<script src="/pagefind/pagefind-ui.js"></script>\n'
              '<script>new PagefindUI({element: "#search", showSubResults: true, showImages: false, autofocus: true});</script>\n')
    body = f'<h1>Web reference: {html.escape(names)}</h1>\n{search}<h2>Documentation</h2>\n<ul class="docs">\n' + '\n'.join(items) + '\n</ul>'
    write(SITE / 'index.html', page(f'Web reference: {names}', body, names, indexed=False,
                                    head='<link rel="stylesheet" href="/pagefind/pagefind-ui.css">\n'))
    write(SITE / 'style.css', STYLE)


if __name__ == '__main__':
    main(sys.argv[1:])
