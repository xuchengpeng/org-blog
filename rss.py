from bs4 import BeautifulSoup
from feedgen.feed import FeedGenerator
from datetime import datetime
from pytz import timezone
import os
import fnmatch

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

author = {"name": "Chuck", "email": "330476629@qq.com"}
china = timezone("Asia/Shanghai")
base_url = "https://xuchengpeng.cn/"

fg = FeedGenerator()
fg.title("Chuck")
fg.author(author)
fg.link(href=base_url+"feed.xml", rel="self")
fg.link(href=base_url, rel="alternate")
fg.description("Valar Morghulis. Valar Dohaeris.")
fg.language("en")
fg.lastBuildDate(datetime.now(china))

for html in htmls:
    with open(file=html, encoding="UTF-8") as file:
        url = base_url + html.replace("public/", "", 1)
        soup = BeautifulSoup(file, "html.parser")
        description = soup.find("main", class_="content").text
        # delete blank lines
        # description = "\n".join([line for line in description.split("\n") if line.strip()])
        description_lines = [line for line in description.split("\n") if line.strip()]
        description = ""
        for line in description_lines:
            if len(description.encode("utf-8")) + len(line.encode("utf-8")) > 200:
                break
            description += line
            description += "\n"
        fe = fg.add_entry()
        fe.title(soup.title.string)
        fe.link(href=url)
        fe.description(description if description else soup.title.string)
        fe.author(author)
        fe.guid(url)
        fe.pubDate(datetime.fromtimestamp(os.path.getmtime(html), china))

fg.rss_file("public/feed.xml")
