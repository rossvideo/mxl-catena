
```mermaid
graph LR
  A@{ shape: docs, label: "MP4 Files" } --> B[MP4 → TS]
  B e1@==> C[TS → MXL]
  C2[Test Patterns → MXL]
  C e2@==> D[MXL → NDI]
  C2 e3@==> D
  D e4@==> E[DashBoard]

  subgraph MXL Providers
    C
    C2
  end
  e1@{ animate: true }
  e2@{ animate: false }
  e3@{ animate: false }
  e4@{ animate: false }

```
