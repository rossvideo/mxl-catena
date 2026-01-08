### Pulling the Demo
#### Requierments 
- have wsl or linux
- install docker with docker compose
- install git

#### Steps
1. In wsl navigate to your home 
    ```
    cd ~
    ```
2. run 
    ```
    git clone https://srvottgitlab02.rossvideo.com/rrl/mxl-demo.git
    ```

---
### Running the Demo
1. Make sure dashboard is closed before starting 
2. Open a WSL terminal and run:
    ```
    cd mxl-demo
    docker compose up -d
    ```
3. Open "http://localhost" in your web browser to access the demo interface.
4. Follow the instructions in the "Viewing the Demo" section below.

### Stopping the Demo
Open a WSL terminal and run:
```
cd mxl-demo
docker compose down
```

### Viewing the Demo
Follow these steps in the browser:

1. Start the MXL stream writer
	- In the control Diagram at the top, Click "TS → MXL".
	- Wait until the indicator turns green.

2. Start the MXL reader and NDI output
	- Click "MXL → NDI".
	- Confirm the indicator is green.
	- Note: Start "TS → MXL" before "MXL → NDI" to ensure a valid MXL stream to read from.

3. Optional: Stream an MP4 as TS
	- Click "Change the Video".
	- Select one of the available MP4 files.
	- Click "Start Stream". It goes live automatically, so the indicator should already be green.

---

### Status Stoplight:
- 🔴 Error: the device has an error
- ⚪ Stopped: the device is stopped (Grey)
- 🟢 Running: the device is running (Green)

### Showing the NDI stream in Dashboard
Open dashboard and add a new Connection. Select "Catena Device" under "Catena" and enter the following details:

|          |          |
|--------------|--------------|
| Hostname     | localhost    |
| Display Name | MXL to NDI   |
| Port         | 7254         |
| Use SSL      | ☐ Unchecked |

Click "Finish" to add the connection.

> You can also add the TS to MXL Catena Device to dashboard using the same steps but with port `7253`, and display name `TS to MXL`.
---

## FAQ
### My dashbord has loaded but i dont see the video:
In Dashboard on the "MXL to NDI" page, "Demo Controls" tab you can see the NDI video output, if it does not appear right away, click the "Refresh" button at the bottom dashboard page. You can also select which input stream to view by click on the desired "Select Source" button. It will switch between the video file loop and the test pattern.
