
```mermaid
---
title: Control Plain
---
graph LR
  mp4Files@{ shape: docs, label: "MP4 Files" }
  mp4Change>Change the Video]
  mp42ts(<span class="led led-red" id="led-mp42ts" title="MP4→TS status"></span>MP4 → TS)
  ts2mxl(<span class="led led-red" id="led-ts2mxl" title="TS→MXL status"></span>TS → MXL)
  pat2mxl(<span class="led led-red" id="led-pat2mxl" title="Test Patterns → MXL status"></span>Test Patterns → MXL)
  mxl2ndi(<span class="led led-red" id="led-mxl2ndi" title="MXL→NDI status"></span>MXL → NDI)

  mp4Files --> mp42ts
  mp4Change -...- mp42ts
  mp42ts e1@==> ts2mxl
  ts2mxl e2@==> mxl2ndi
  pat2mxl e3@==> mxl2ndi
  mxl2ndi e4@==> dashboard[DashBoard]

  click mp4Change "http://localhost:3000" "Open MP4 to TS Stream Page" _blank
  click ts2mxl toggleTs2Mxl "Toggle TS to MXL Stream"
  click mxl2ndi toggleMxl2Ndi "Toggle MXL to NDI Stream"

  %% Button-like styling and click states
  classDef buttonClickable fill:#e0f2fe,stroke:#0284c7,stroke-width:2px,color:#0c4a6e;
  classDef buttonDisabled fill:#f3f4f6,stroke:#d1d5db,stroke-width:1px,color:#9ca3af;
  %% Make a clear sub graph
  style Demo_Videos stroke:none,fill:transparent,color:none;
  class mp4Change,ts2mxl,mxl2ndi buttonClickable;
  class mp42ts,mp4Files,dashboard,pat2mxl buttonDisabled;

  subgraph MXL Providers
    ts2mxl
    pat2mxl
  end
  subgraph Demo_Videos[" "]
    mp4Files
    mp4Change
  end
  e1@{ animation: false }
  e2@{ animate: false }
  e3@{ animation: false }
  e4@{ animate: false }

```
- **MP4 Files**: A collection of sample MP4 video files used as input for the demo.
- **MP4 → TS**: Converts MP4 files to MPEG-TS format.
- **Test Patterns → MXL**: Generates MXL streams from a test pattern.
- **TS → MXL**: Converts TS streams to MXL format.
- **MXL → NDI**: Converts MXL streams to NDI format for video production workflows.