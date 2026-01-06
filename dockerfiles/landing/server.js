const express = require('express');
const fs = require('fs');
const path = require('path');
const { marked } = require('marked');

const app = express();
const PORT = process.env.PORT || 8080;
const README_PATH = process.env.README_PATH || '/app/README.md';

marked.setOptions({
  mangle: false,
  headerIds: true
});

app.use('/public', express.static(path.join(__dirname, 'public')));

function renderTemplate(htmlContent) {
  const templatePath = path.join(__dirname, 'views', 'index.html');
  const template = fs.readFileSync(templatePath, 'utf8');
  return template.replace('{{content}}', htmlContent);
}

app.get('/', (req, res) => {
  fs.readFile(README_PATH, 'utf8', (err, md) => {
    if (err) {
      res.status(500).send(`Failed to read README: ${err.message}`);
      return;
    }
    const html = marked.parse(md);
    const fullPage = renderTemplate(html);
    res.send(fullPage);
  });
});

app.listen(PORT, () => {
  console.log(`Landing page listening on http://0.0.0.0:${PORT}`);
});
