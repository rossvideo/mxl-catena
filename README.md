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
Open a web browser and navigate to `http://localhost` to access the demo interface. Once there click on the "TS → MXL" button to go live with the MXL stream writer. The indicator should turn green once the stream is live. Then click on the "MXL → NDI" button to go live with the MXL reader. It will also output an NDI stream viewable in Dashboard. The indicator should also turn green once the stream is live. Make sure to start the "TS → MXL" before starting the "MXL → NDI" so that there is a valid MXL stream to read from.

If you click on the "MP4 → TS" button, it will open another page to select which of the available MP4 files to stream as TS. Select one of the files and click "Start Stream" button. This will go live automatically, so the indicator should already be green.

Open dashboard and add a new Connection. Select "Catena Device" under "Catena" and enter the following details:
- Hostname: `localhost`
- Display Name: `MXL to NDI`
- Port: `7254`
- Make sure "Use SSL" is unchecked.

Click "Finish" to add the connection.

You can also add the TS to MXL Catena Device to dashboard using the same steps but with port `7253`, and display name `TS to MXL`.

In Dashboard on the "MXL to NDI" page, "Demo Controls" tab you can see the NDI video output, if it does not appear right away, click the "Refresh" button at the bottom dashboard page. You can also select which input stream to view by click on the desired "Select Source" button. It will switch between the video file loop and the test pattern.

---
### Architecture

### Components
- **mp42ts**: Converts MP4 files to MPEG-TS format.
- **pat2mxl**: Generates MXL streams from a test pattern.
- **ts2mxl**: Converts TS streams to MXL format.
- **mxl2ndi**: Converts MXL streams to NDI format for video production workflows.
