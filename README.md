# MXL Demo

Cool MXL DEMO

---
### Running the Demo
```
docker compose up -d
```

### Stopping the Demo
```
docker compose down
```

### Viewing the Demo
Open a web browser and navigate to `http://localhost` to access the demo interface.

---
### Architecture

### Components
- **mp42ts**: Converts MP4 files to MPEG-TS format.
- **pat2mxl**: Generates MXL streams from a test pattern.
- **ts2mxl**: Converts TS streams to MXL format.
- **mxl2ndi**: Converts MXL streams to NDI format for video production workflows.
