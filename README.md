# certificate_generator

## Tonton Jo  
### Join the community:
[![Youtube](https://badgen.net/badge/Youtube/Subscribe)](http://youtube.com/channel/UCnED3K6K5FDUp-x_8rwpsZw?sub_confirmation=1)
[![Discord Tonton Jo](https://badgen.net/discord/members/h6UcpwfGuJ?label=Discord%20Tonton%20Jo%20&icon=discord)](https://discord.gg/h6UcpwfGuJ)
### Support my work, give a thanks and help the youtube channel:
[![Ko-Fi](https://badgen.net/badge/Buy%20me%20a%20Coffee/Link?icon=buymeacoffee)](https://ko-fi.com/tontonjo)
[![Infomaniak](https://badgen.net/badge/Infomaniak/Affiliated%20link?icon=K)](https://www.infomaniak.com/goto/fr/home?utm_term=6151f412daf35)
[![Express VPN](https://badgen.net/badge/Express%20VPN/Affiliated%20link?icon=K)](https://www.xvuslink.com/?a_fid=TontonJo)  
## Sources:  
[Stackoverflow](https://stackoverflow.com/questions/26759550/how-to-create-own-self-signed-root-certificate-and-intermediate-ca-to-be-importe)  

## Demonstration:  
[Youtube](https://www.youtube.com/watch?v=pqqEBFnOb5g)  

## Description:
This script aims to create a root CA, an intermediate CA and then certificates, wildcard or not, for your hosts
in dedicated subfolders.  
After generation, a subfolder named "hosts-certs\\*\pack" who contain the root, intermediate and fullchain certificate will be created 
The script also generate a bat script named certificate_importer.bat in each pack folder intended to import all certificates for trust on Windows hosts.  

I'm not very used to certificates generation and management so if you find something strange, please let me know or make a PR.  

# Usage:
- Ensure you have openssl installed
```shell
apt-get install openssl
```
- Download script
```shell
wget -q -O certificate_generator.sh https://github.com/Tontonjo/certificate_generator/raw/main/certificate_generator.sh
```
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
