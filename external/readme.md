 # Exeranl  resources
 
 This directory holds runtime libraries and executables required by MXL Catena devices.
 ---
 ### How to populate:
 - From the project root, run:
   - ts-builder.sh
   - ndi-builder.sh
 > These builder scripts fetch/build the necessary artifacts and stage them here in the expected layout.
---
 ### Usage:
 - Build/deploy pipelines reference this directory when assembling device images and runtime environments.
 - Do not place ad‑hoc binaries here; use the builder scripts to ensure correct versions and structure.

 ### Maintenance:
 - Re-run the builders to update content.
 - Ensure the scripts are executable and required tooling/dependencies are installed (see script headers).
 - Avoid storing secrets. If size is a concern, prefer CI artifact storage/caching over committing large binaries.