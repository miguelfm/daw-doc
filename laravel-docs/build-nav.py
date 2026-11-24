#!/usr/bin/env python3
"""
Xera automaticamente o ficheiro mkdocs.yml a partir dos docs de Laravel.
Organiza a navegación por categorías lóxicas para facilitar a consulta.
"""

import os
import re
import yaml

DOCS_DIR = "/docs"
OUTPUT_FILE = "/mkdocs.yml"

NAVIGATION = {
    "Primeiros Pasos": [
        "installation",
        "configuration",
        "directory-structure",
        "frontend",
        "starter-kits",
        "deployment",
    ],
    "Arquitectura": [
        "lifecycle",
        "container",
        "providers",
        "facades",
    ],
    "Fundamentos": [
        "routing",
        "middleware",
        "csrf",
        "controllers",
        "requests",
        "responses",
        "views",
        "blade",
        "urls",
        "session",
        "validation",
        "errors",
        "logging",
    ],
    "Base de Datos": [
        "database",
        "queries",
        "pagination",
        "migrations",
        "seeding",
    ],
    "Eloquent ORM": [
        "eloquent",
        "eloquent-relationships",
        "eloquent-collections",
        "eloquent-mutators",
        "eloquent-resources",
        "eloquent-serialization",
        "eloquent-factories",
    ],
    "Seguridade": [
        "authentication",
        "authorization",
        "verification",
        "encryption",
        "hashing",
        "passwords",
        "sanctum",
    ],
    "Testing": [
        "testing",
        "http-tests",
        "console-tests",
        "browser-tests",
        "database-testing",
        "mocking",
    ],
    "Paquetes e API": [
        "packages",
        "collections",
        "helpers",
        "http-client",
        "strings",
        "filesystem",
        "cache",
        "events",
        "mail",
        "notifications",
        "queues",
    ],
    "Ferramentas": [
        "artisan",
        "broadcasting",
        "envoy",
        "folio",
        "fortify",
        "homestead",
        "horizon",
        "mix",
        "octane",
        "passport",
        "pint",
        "pennant",
        "precognition",
        "processes",
        "prompts",
        "pulse",
        "rate-limiting",
        "reverb",
        "sail",
        "scout",
        "socialite",
        "telescope",
        "valet",
        "vite",
    ],
}


def get_title_from_md(filepath):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("# "):
                    return line[2:].strip()
    except Exception:
        pass
    name = os.path.splitext(os.path.basename(filepath))[0]
    return name.replace("-", " ").title()


def get_available_docs():
    docs = {}
    if not os.path.isdir(DOCS_DIR):
        print(f"ERRO: Non se atopa o directorio {DOCS_DIR}")
        return docs
    for filename in os.listdir(DOCS_DIR):
        if filename.endswith(".md"):
            slug = filename[:-3]
            filepath = os.path.join(DOCS_DIR, filename)
            title = get_title_from_md(filepath)
            docs[slug] = {"title": title, "file": filename}
    return docs


def build_nav(available_docs):
    nav = [{"Inicio": "index.md"}]
    used_slugs = {"index"}
    for category, slugs in NAVIGATION.items():
        items = []
        for slug in slugs:
            if slug in available_docs:
                doc = available_docs[slug]
                items.append({doc["title"]: doc["file"]})
                used_slugs.add(slug)
        if items:
            nav.append({category: items})
    others = []
    for slug, doc in sorted(available_docs.items()):
        if slug not in used_slugs:
            others.append({doc["title"]: doc["file"]})
    if others:
        nav.append({"Outros": others})
    return nav


def generate_mkdocs_yml(nav):
    config = {
        "site_name": "Laravel Documentation",
        "site_description": "Documentación offline de Laravel para DAW",
        "site_url": "",
        "use_directory_urls": False,
        "theme": {
            "name": "material",
            "language": "en",
            "palette": [
                {
                    "scheme": "default",
                    "primary": "red",
                    "accent": "red",
                    "toggle": {
                        "icon": "material/brightness-7",
                        "name": "Cambiar a modo escuro",
                    },
                },
                {
                    "scheme": "slate",
                    "primary": "red",
                    "accent": "red",
                    "toggle": {
                        "icon": "material/brightness-4",
                        "name": "Cambiar a modo claro",
                    },
                },
            ],
            "features": [
                "navigation.instant",
                "navigation.tracking",
                "navigation.sections",
                "navigation.expand",
                "navigation.top",
                "search.suggest",
                "search.highlight",
                "search.share",
                "content.code.copy",
                "toc.follow",
            ],
            "icon": {"logo": "material/book-open-variant"},
        },
        "plugins": [
            {
                "search": {
                    "lang": "en",
                    "separator": r'[\s\-\.]+',
                }
            },
        ],
        "markdown_extensions": [
            "admonition",
            "pymdownx.details",
            "pymdownx.superfences",
            {
                "pymdownx.highlight": {
                    "anchor_linenums": True,
                    "use_pygments": True,
                }
            },
            "pymdownx.inlinehilite",
            "pymdownx.snippets",
            "pymdownx.tabbed",
            "tables",
            {
                "toc": {
                    "permalink": True,
                    "toc_depth": 3,
                }
            },
        ],
        "docs_dir": DOCS_DIR,
        "nav": nav,
        "extra": {
            "generator": False,
        },
        "extra_css": [],
    }
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        yaml.dump(config, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
    print(f"Xerado {OUTPUT_FILE} con {sum(len(v) for cat in nav for v in cat.values() if isinstance(v, list))} páxinas")


def fix_laravel_markdown():
    if not os.path.isdir(DOCS_DIR):
        return
    for filename in os.listdir(DOCS_DIR):
        if not filename.endswith(".md"):
            continue
        filepath = os.path.join(DOCS_DIR, filename)
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            original = content
            content = re.sub(r'<a\s+name="([^"]+)"\s*>\s*</a>', r'', content)
            content = re.sub(r'>\s*\{tip\}\s*', '!!! tip\n    ', content)
            content = re.sub(r'>\s*\{note\}\s*', '!!! note\n    ', content)
            content = re.sub(r'>\s*\{warning\}\s*', '!!! warning\n    ', content)
            if content != original:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"  Corrixido: {filename}")
        except Exception as e:
            print(f"  Erro procesando {filename}: {e}")


def create_index_page():
    """Crea un index.md se non existe no repo de Laravel."""
    index_path = os.path.join(DOCS_DIR, "index.md")
    if os.path.exists(index_path):
        return
    content = """# Laravel Documentation

Benvido/a á documentación offline de Laravel para DAW.

Usa o **buscador** (icona da lupa arriba) para atopar calquera tema rapidamente.

## Primeiros Pasos

- [Instalación](installation.md)
- [Configuración](configuration.md)
- [Estrutura de directorios](directory-structure.md)
- [Starter Kits](starter-kits.md)

## Temas principais

- [Routing](routing.md)
- [Controllers](controllers.md)
- [Middleware](middleware.md)
- [Blade Templates](blade.md)
- [Eloquent ORM](eloquent.md)
- [Validación](validation.md)
- [Autenticación](authentication.md)
- [Migracións](migrations.md)
"""
    with open(index_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("  Creado index.md")


if __name__ == "__main__":
    print("=== Xerando configuración MkDocs para Laravel Docs ===")
    print("\n1. Creando páxina de inicio...")
    create_index_page()
    print("\n2. Corrixindo ficheiros markdown...")
    fix_laravel_markdown()
    print("\n2. Escaneando documentación dispoñible...")
    available = get_available_docs()
    print(f"   Atopados {len(available)} ficheiros .md")
    print("\n3. Construíndo navegación...")
    nav = build_nav(available)
    print("\n4. Xerando mkdocs.yml...")
    generate_mkdocs_yml(nav)
    print("\n=== Listo! ===")
