"""Desempaqueta o db.json de cada documentación de DevDocs en ficheiros
.html, para servilos sen conexión."""
import json, os, glob
for db_file in glob.glob("docs/*/db.json"):
    lang_dir = os.path.dirname(db_file)
    with open(db_file) as f:
        data = json.load(f)
    for k, v in data.items():
        p = os.path.join(lang_dir, k + ".html")
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8") as out:
            out.write(v)
