### Running the Demo
1. Make sure dashboard is closed before starting 
2. Open a WSL terminal and run:
```
cd /path/to/mxl-demo
docker compose up -d
```
3. Open "http://localhost" in your web browser to access the demo interface.
4. Follow the instructions in the "Viewing the Demo" section below.

### Stopping the Demo
Open a WSL terminal and run:
```
cd /path/to/mxl-demo
docker compose down
```

### Viewing the Demo
In the browser, click on the "TS → MXL" button to go live with the MXL stream writer. The indicator should turn green once the stream is live. Then click on the "MXL → NDI" button to go live with the MXL reader. It will also output an NDI stream viewable in Dashboard. The indicator should also turn green once the stream is live. Make sure to start the "TS → MXL" before starting the "MXL → NDI" so that there is a valid MXL stream to read from.

If you click on the "MP4 → TS" button, it will open another page to select which of the available MP4 files to stream as TS. Select one of the files and click "Start Stream" button. This will go live automatically, so the indicator should already be green.

A Grey indicator means the device is stopped, Red means there is an error, and Green means the device is running.

Open dashboard and add a new Connection. Select "Catena Device" under "Catena" and enter the following details:
- Hostname: `localhost`
- Display Name: `MXL to NDI`
- Port: `7254`
- Make sure "Use SSL" is unchecked.

Click "Finish" to add the connection.

You can also add the TS to MXL Catena Device to dashboard using the same steps but with port `7253`, and display name `TS to MXL`.

In Dashboard on the "MXL to NDI" page, "Demo Controls" tab you can see the NDI video output, if it does not appear right away, click the "Refresh" button at the bottom dashboard page. You can also select which input stream to view by click on the desired "Select Source" button. It will switch between the video file loop and the test pattern.
