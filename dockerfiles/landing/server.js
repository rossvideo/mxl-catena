const express = require('express');
const fs = require('fs');
const path = require('path');
const { marked } = require('marked');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const app = express();
const PORT = process.env.PORT || 8080;
const README_PATH = process.env.README_PATH || '/app/README.md';
const UML_PATH = process.env.UML_PATH || '/app/UML.md';
const PROTOS_PATH = path.join(__dirname, 'proto', 'service.proto');

const packageDefinition = protoLoader.loadSync(PROTOS_PATH,
  {
    keepCase: true,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true
  }
);
const protoDescriptor = grpc.loadPackageDefinition(packageDefinition);
const st2138 = protoDescriptor.st2138;
const ts2mxlClient = new st2138.CatenaService('ts2mxl:6254', grpc.credentials.createInsecure());
const mxl2ndiClient = new st2138.CatenaService('mxl2ndi:6254', grpc.credentials.createInsecure());

marked.setOptions({
  mangle: false,
  headerIds: true
});

app.use('/public', express.static(path.join(__dirname, 'public')));
// Serve mounted assets (icons/images) from /app so UML.md inline icons resolve
app.use(express.static('/app'));

function renderTemplate(htmlContent) {
  const templatePath = path.join(__dirname, 'views', 'index.html');
  const template = fs.readFileSync(templatePath, 'utf8');
  return template.replace('{{content}}', htmlContent);
}

app.get('/', (req, res) => {
  // Read UML (optional) then README and render with UML first
  fs.readFile(UML_PATH, 'utf8', (umlErr, umlMd) => {
    const umlHtml = (!umlErr && umlMd) ? marked.parse(umlMd) : '';
    fs.readFile(README_PATH, 'utf8', (err, md) => {
      if (err) {
        res.status(500).send(`Failed to read README: ${err.message}`);
        return;
      }
      const readmeHtml = marked.parse(md);
      const html = `${umlHtml}\n${readmeHtml}`;
      const fullPage = renderTemplate(html);
      res.send(fullPage);
    });
  });
});

const handleCommand = (client, oid) => {
  return (req, res) => {
    client.ExecuteCommand({
      slot: 0,
      oid: oid,
      value: {},
      respond: false,
    });
    res.json({ status: 'executed', command: oid });
  };
};

const handleGetValue = (client, oid) => {
  return (req, res) => {
    client.GetValue({
      slot: 0,
      oid: oid,
    }, (err, response) => {
      if (err) {
        res.status(500).json({ error: err.message });
        return;
      }
      res.json(response);
    });
  };
}

app.get('/api/ts2mxl/status', handleGetValue(ts2mxlClient, "/status"));
app.post('/api/ts2mxl/start', handleCommand(ts2mxlClient, "/start"));
app.post('/api/ts2mxl/stop', handleCommand(ts2mxlClient, "/stop"));
app.get('/api/mxl2ndi/status', handleGetValue(mxl2ndiClient, "/status"));
app.post('/api/mxl2ndi/start', handleCommand(mxl2ndiClient, "/start"));
app.post('/api/mxl2ndi/stop', handleCommand(mxl2ndiClient, "/stop"));

app.listen(PORT, () => {
  console.log(`Landing page listening on http://0.0.0.0:${PORT}`);
});
