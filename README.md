# certificate_generator

# Tonton Jo - 2020
## Join me on Youtube: https://www.youtube.com/c/TontonJo

## Sources:  
https://stackoverflow.com/questions/26759550/how-to-create-own-self-signed-root-certificate-and-intermediate-ca-to-be-importe

## Description:
This script aims to create a root CA, an intermediate CA and then certificates, wildcard or not, for your hosts
in dedicated subfolders.
After generation, a subfolder named "hosts-certs\*\pack" who contaain the root, intermediate and fullchain certificate to be imported on youur hosts for trust.
The script also generate a bat script named certificate_importer.bat in eache pack folder intende to import all certs for trust on Windows hosts  
I'm not very used to certificates generation and management so if you find something strange, please let me know or make a PR.

# Usage:
- Ensure you have openssl installed
```shell
apt-get install openssl
```
- Download script
- Open it, and edit the "settings" section according to your needs
- - Generate a wildcard certificate:
```shell
bash certificate_generator.sh
```
- - Generate a dedicated certificate for one or more hosts - Each host will have his own certificate and private key
```shell
bash certificate_generator.sh server1 server2 server3
```
- You should now have a folder named "certificate" with all your certificates.
- - Certificates for your hosts are located in "hosts-certs"

If you want to add trust of your new certificate for your hosts, depending on them, you need to import fullchain and / or root and intermediate certificates.
- For windows hosts, you can copy the "pack" folder and run certificate_importer.bat on each host you want.
