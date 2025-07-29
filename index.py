import os
import fnmatch
import json
from dataclasses import dataclass
from bs4 import BeautifulSoup

@dataclass
class Entry:
    title: str
    description: str
    keywords: str
    url: str

htmls = []
for root, dirs, files in os.walk(os.getcwd() + "/public/posts"):
    relpath = os.path.relpath(root)
    for filename in fnmatch.filter(files, "*.html"):
        if filename == "index.html":
            continue
        filename = os.path.join(relpath, filename)
        filename = filename.replace("\\", "/")
        htmls.append(filename)
htmls.sort()

entries = []
for html in htmls:
    with open(file=html, encoding="UTF-8") as file:
        url = html.replace("public/", "/", 1)
        soup = BeautifulSoup(file, "html.parser")
        title = soup.title.string
        description = soup.find("meta", attrs={"name": "description"})
        keywords = soup.find("meta", attrs={"name": "keywords"})
        entries.append(Entry(title, description["content"] if description else "", keywords["content"] if keywords else "", url))

with open("public/index.json", "w", encoding="utf-8", newline="\n") as f:
    f.write(json.dumps([ob.__dict__ for ob in entries]))
