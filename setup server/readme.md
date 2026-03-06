# Stetting up the server

- you will need to make an id_ed25519 key pair
- the public key should be named id_ed25519.pub
- copy `setup.sh` to the server and run it in the same dir as the key pair
---
## Configer Project to target your server
- change the ips in the tofu `providers.tf`, `main.tf`, ...
- change the ip in the upload script `upload.sh`
- run the `ts-builder.sh` and `ndi-builder.sh`
- then run `upload.sh`
---
once its setup you should beable to `./tofu setup` then `./tofu start`
