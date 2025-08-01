const fs = require('fs').promises;
const path = require('path');
const cheerio = require('cheerio');

async function parseHtmls() {
  const entries = [];

  try {
    for (const dir of ["posts", "notes"]) {
      const inputDir = './public/' + dir;
      const files = await fs.readdir(inputDir);
      for (const file of files) {
        if (file !== 'index.html' && path.extname(file).toLowerCase() === '.html') {
          const filePath = path.join(inputDir, file);
          try {
            const htmlContent = await fs.readFile(filePath, 'utf8');
            const $ = cheerio.load(htmlContent);
            const title = $('title').text();
            const description = $('meta[name=description]').attr('content');
            const keywords = $('meta[name=keywords]').attr('content');
            const url = '/' + dir + '/' + file;
            entries.push({
              title: title || '',
              description: description || '',
              keywords: keywords || '',
              url: url
            });
          } catch (readErr) {
            console.error(`Error reading or parsing ${file}:`, readErr.message);
          }
        }
      }
    }
    await fs.writeFile('./public/index.json', JSON.stringify(entries), 'utf8');
  } catch (dirErr) {
    console.error(`Error accessing directory ${inputDir}:`, dirErr.message);
  }
}

parseHtmls();
