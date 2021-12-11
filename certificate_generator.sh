#!/bin/bash

# Tonton Jo - 2021
# Join me on Youtube: https://www.youtube.com/c/tontonjo

# This script aims to create a root CA, an intermediate CA and then certificates, wildcard or not, for your hosts
# in dedicated subfolders, and put a script in each to quickly deploy the root and intermediate certificate on your hosts

# Disclaimer:
# I'm not very used to certificates generation and management so if you find something strange, please let me know
# This script has been created for fun and to play with certificate generation
# This is indeed not intended for production use

# Sources:
# https://stackoverflow.com/questions/26759550/how-to-create-own-self-signed-root-certificate-and-intermediate-ca-to-be-importe

# Usage:
# Edit configurations according to your need in "settings" section.
# Generate a wildcard certificate:
# - bash certificate_generator.sh
# Generate a dedicated certificate for one or more hosts - Each host will have a dedicated certificate
# - bash certificate_generator.sh server1 server2 server3
# Script will generate a .bat script in each folder aimed to easilly import needed certificates on windows hosts.

# Version: 1.0 - Initial release
# Version: 1.1 - Add out for new hosts if argument specified
# Version: 2.0 - Lots of changes
# Version: 2.1 - Edit path and pack creation - rename certificates
# Version: 2.2 - prepare for ecdsa
# Version: 2.3 - Fix path to create fullchain
# Version: 2.4 - Edit some paths
# Version: 2.5 - add check for openssl installation
# Version: 2.6 - small fixes - correction of cnames
# Version: 2.7 - fix generation of certificates

# ------------- Settings ------------------
tld="local.domain.tld"
country="fr"
state="Vaucluse"
town="Lyon"
organisation="Home"
rootCAvalidity="36500"
certvalidity="3650"
# ------------- Settings ------------------


if openssl help > /dev/null 2>&1 ; then
    
cd "$(dirname "$0")"

# if directory exist skip creation of root-ca and intermediate:
if [ -d "./certificate" ]; then
	echo "Certificate folder already exist - Using existing configuration"
else
	for C in `echo root-ca intermediate`; do

	  mkdir -p "./certificate/$C"
	  cd "./certificate/$C"
	  mkdir certs crl newcerts private
	  cd ..
	  cd ..
	  echo 1000 > ./certificate/$C/serial
	  touch "./certificate/$C/index.txt" "./certificate/$C/index.txt.attr"
	done
	echo "
	[ ca ]
	default_ca = CA_default
	
	[ CA_default ]
	dir            = "./certificate"                  				  # Where everything is kept
	certs          = "./certificate/certs"            			      # Where the issued certs are kept                    # Where the issued crl are kept
	database       = "./certificate/intermediate/index.txt"           # database index file.
	new_certs_dir  = "./certificate/intermediate/newcerts"            # default place for new certs.
	certificate    = "./certificate/root-ca/certs/ca_crt.crt"         # The CA certificate
	serial         = "./certificate/intermediate/serial"   	          # The current serial number
	private_key    = "./certificate/root-ca/private/ca_key.pem" 	  # The private key
	RANDFILE       = "./.rnd"                					      # private random number file
	nameopt        = root_CA
	certopt        = root_CA
	policy         = policy_match
	default_days   = $rootCAvalidity
	default_md     = sha256
	unique_subject = yes
	email_in_dn    = no
	rand_serial	   = no
	
	[ policy_match ]
	countryName            = optional
	stateOrProvinceName    = optional
	organizationName       = optional
	organizationalUnitName = optional
	commonName             = supplied
	emailAddress           = optional

	[req]
	req_extensions = v3_req
	distinguished_name = req_distinguished_name
	
	[ req_ext ]
	subjectAltName = @alternate_names
	extendedKeyUsage = serverAuth
	
	[v3_req]
	basicConstraints = CA:TRUE
	
	[req_distinguished_name]

	[ alternate_names ]
	DNS.1 = *.$tld
	" > "./certificate/openssl.conf"
	openssl genrsa -out "./certificate/root-ca/private/ca_key.pem" 2048
#	openssl ecparam -name prime256v1 -genkey -noout -out "./certificate/root-ca/private/ca_key.pem"
	openssl req -config "./certificate/openssl.conf" -new -x509 -days $rootCAvalidity -utf8 -nameopt multiline,utf8 -key "./certificate/root-ca/private/ca_key.pem" -sha256 -extensions v3_req -out "./certificate/root-ca/certs/ca_crt.crt" -subj "/C=$country/ST=$state/O=$organisation/CN=$tld/L=$town"
	openssl genrsa -out "./certificate/intermediate/private/intermediate_key.pem" 2048
#	openssl ecparam -name prime256v1 -genkey -noout -out "./certificate/intermediate/private/intermediate_key.pem"
	openssl req -config "./certificate/openssl.conf" -sha256 -new -utf8 -nameopt multiline,utf8 -key "./certificate/intermediate/private/intermediate_key.pem" -out "./certificate/intermediate/certs/intermediate.csr" -subj "/CN=$tld"
	openssl ca -batch -policy policy_match -config "./certificate/openssl.conf" -keyfile "./certificate/root-ca/private/ca_key.pem" -cert "./certificate/root-ca/certs/ca_crt.crt" -extensions v3_req -notext -md sha256 -in "./certificate/intermediate/certs/intermediate.csr" -out "./certificate/intermediate/certs/intermediate_crt.crt"


fi

# If nothing passed as argument, generate a wildcard for TLD
if [ -z "$@" ]; then
		echo "No hostname specified "
		if [[ -d "./certificate/hosts-certs/wildcard" ]]; then
			echo "- Wildcard certificate already exist"
		else
			mkdir -p "./certificate/hosts-certs/wildcard/pack"
			openssl req -config "./certificate/openssl.conf" -new -nodes -utf8 -nameopt multiline,utf8 -extensions req_ext -newkey rsa:2048 -keyout "./certificate/hosts-certs/wildcard/wildcard_key.pem" -out "./certificate/hosts-certs/wildcard/server.request" -nodes -subj "/CN=$I.$tld/C=$country/ST=$state/O=$organisation/L=$town"
#			openssl req -config "./certificate/openssl.conf" -new -nodes -utf8 -nameopt multiline,utf8 -extensions req_ext -newkey ec:<(openssl ecparam -name prime256v1) -keyout "./certificate/hosts-certs/wildcard/wildcard_key.pem" -out "./certificate/hosts-certs/wildcard/server.request" -nodes -subj "/CN=*.$tld/C=$country/ST=$state/O=$organisation/L=$town"
			openssl ca -batch -notext -policy policy_match -days $certvalidity -extensions req_ext -config "./certificate/openssl.conf" -keyfile "./certificate/intermediate/private/intermediate_key.pem" -cert "./certificate/intermediate/certs/intermediate_crt.crt" -out "./certificate/hosts-certs/wildcard/wildcard_crt.crt" -infiles "./certificate/hosts-certs/wildcard/server.request"
			cp "./certificate/root-ca/certs/ca_crt.crt" "./certificate/hosts-certs/wildcard/pack"
			cp "./certificate/intermediate/certs/intermediate_crt.crt" "./certificate/hosts-certs/wildcard/pack"
			cp "./certificate/hosts-certs/wildcard/wildcard_crt.crt" "./certificate/hosts-certs/wildcard/pack"
			cp "./certificate/root-ca/certs/ca_crt.crt" "./certificate/hosts-certs/wildcard/pack/fullchain.crt"
			cat "./certificate/intermediate/certs/intermediate_crt.crt" >> "./certificate/hosts-certs/wildcard/pack/fullchain.crt"
			cat "./certificate/hosts-certs/wildcard/wildcard_crt.crt" >> "./certificate/hosts-certs/wildcard/pack/fullchain.crt"
			echo '@echo off
REM Version 1.0
REM Execute as administrator in folder containing all the .crt to import
echo "----------------------------------------------------------------"
echo "---------------------- Tonton Jo - 2021 ------------------------"
echo "------------- Windows certificate Importer V1.0 ----------------"
echo "----------------------------------------------------------------"
for %%f in (%~dp0*.crt) do (
echo "- Importing %%f"
certutil.exe -enterprise -f -v -AddStore "Root" %%f
)
PAUSE' > "./certificate/hosts-certs/wildcard/pack/certificate_importer.bat"
		fi
	else
	# If hostname argument passed, generate a certificate for every host
	for I in "$@" ; do
	if [[ -d "./certificate/hosts-certs/$I" ]]; then
			echo "- Certificate already exist"
		else
			mkdir -p "./certificate/hosts-certs/$I/pack"
			echo "subjectAltName = DNS:$I.$tld
extendedKeyUsage = serverAuth" > "./certificate/hosts-certs/$I/subjectaltname_$I.req"
			openssl req -config "./certificate/openssl.conf" -new -nodes -utf8 -nameopt multiline,utf8 -extensions req_ext -newkey rsa:2048 -keyout "./certificate/hosts-certs/$I/key.pem" -out "./certificate/hosts-certs/$I/$I.request" -nodes -subj "/CN=$tld/C=$country/ST=$state/O=$organisation/L=$town"
#			openssl req -config "./certificate/openssl.conf" -new -nodes -utf8 -nameopt multiline,utf8 -extensions req_ext -newkey ec:<(openssl ecparam -name prime256v1) -keyout "./certificate/hosts-certs/$I/$I.key" -out "./certificate/hosts-certs/$I/$I.request" -nodes -subj "/CN=$I.$tld/C=$country/ST=$state/O=$organisation/L=$town"
			openssl ca -batch -notext -policy policy_match -days $certvalidity -extfile "./certificate/hosts-certs/$I/subjectaltname_$I.req" -config "./certificate/openssl.conf" -keyfile "./certificate/intermediate/private/intermediate_key.pem" -cert "./certificate/intermediate/certs/intermediate_crt.crt" -out "./certificate/hosts-certs/$I/$I.crt" -infiles "./certificate/hosts-certs/$I/$I.request"
			cp "./certificate/root-ca/certs/ca_crt.crt" "./certificate/hosts-certs/$I/pack"
			cp "./certificate/intermediate/certs/intermediate_crt.crt" "./certificate/hosts-certs/$I/pack"
			cp "./certificate/hosts-certs/$I/$I.crt" "./certificate/hosts-certs/$I/pack"
			cp "./certificate/root-ca/certs/ca_crt.crt" "./certificate/hosts-certs/$I/pack/fullchain.crt"
			cat "./certificate/intermediate/certs/intermediate_crt.crt" >> "./certificate/hosts-certs/$I/pack/fullchain.crt"
			cat "./certificate/hosts-certs/$I/$I.crt" >> "./certificate/hosts-certs/$I/pack/fullchain.crt"
			echo '@echo off
REM Version 1.0
REM Execute as administrator in folder containing all the .crt to import
echo "----------------------------------------------------------------"
echo "---------------------- Tonton Jo - 2021 ------------------------"
echo "------------- Windows certificate Importer V1.0 ----------------"
echo "----------------------------------------------------------------"
for %%f in (%~dp0*.crt) do (
echo "- Importing %%f"
certutil.exe -enterprise -f -v -AddStore "Root" %%f
)
PAUSE
' > "./certificate/hosts-certs/$I/pack/certificate_importer.bat"
	fi
	done
fi

else
    echo "- Openssl not installed"
	echo "- install with "apt-get install openssl""
fi
