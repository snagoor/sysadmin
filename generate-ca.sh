#! /bin/bash
function read_cert_details() {
echo ""
while [ -z "$CA_COUNTRY_INFO" ]; do read -r -p "Provide Country Code (2 Letters) [IN] : " CA_COUNTRY_INFO; done
while [ -z "$CA_STATE_INFO" ]; do read -r -p "Provide State Information : " CA_STATE_INFO; done
while [ -z "$CA_CITY_INFO" ]; do read -r -p "Provide City Information : " CA_CITY_INFO; done
while [ -z "$CA_ORG_INFO" ]; do read -r -p "Provide Organization Name : " CA_ORG_INFO; done
while [ -z "$CA_DEPT_INFO" ]; do read -r -p "Provide Department Information : " CA_DEPT_INFO; done
while [ -z "$CA_EMAIL_INFO" ]; do read -r -p "Provide Email Address (root@example.com) : " CA_EMAIL_INFO; done
while [ -z "$CA_CN_INFO" ]; do read -r -p "Provide Common Name [Host FQDN (host.example.com)] : " CA_CN_INFO; done
while [ -z $CA_CERT_DAYS ]; do read -r -p "How many days would you like the CA Cert to be valid for? [DAYS] : " CA_CERT_DAYS && validate_days; done
show_cert_details
echo ""
read -r -p "Would you like to proceed with the above selection [Y/N] " READ_INPUT
if [ "$READ_INPUT" == "Y" ] || [ "$READ_INPUT" == "y" ]; then
  write_conf_file
else
  echo -e "\nBased on input receieved, exiting now\n"
  exit
fi
}

function validate_days() {
if ! [[ $CA_CERT_DAYS =~ ^[0-9]+$ ]]; then
  CA_CERT_DAYS=$(echo $CA_CERT_DAYS | bc)
  if [[ $CA_CERT_DAYS -lt 1 ]]; then
    read -r -p "How many days would you like the CA Cert to be valid for? [DAYS] : " CA_CERT_DAYS
    CA_CERT_DAYS=$(echo $CA_CERT_DAYS | bc)
    validate_days
  fi
fi
}

function write_conf_file() {
cat > "$PWD/certs/ca_certs/ca-setup.conf" << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=$CA_COUNTRY_INFO
ST=$CA_STATE_INFO
L=$CA_CITY_INFO
O=$CA_ORG_INFO
OU=$CA_DEPT_INFO
emailAddress=$CA_EMAIL_INFO
CN=$CA_CN_INFO
EOF
}

function show_cert_details() {
echo -e "\nPer your selection below are the details entered\n"
echo -e "\t\tCountry Code\t\t\t: $CA_COUNTRY_INFO"
echo -e "\t\tState Information\t\t: $CA_STATE_INFO"
echo -e "\t\tCity\t\t\t\t: $CA_CITY_INFO"
echo -e "\t\tOrganization\t\t\t: $CA_ORG_INFO"
echo -e "\t\tDepartment\t\t\t: $CA_DEPT_INFO"
echo -e "\t\tCommon Name\t\t\t: $CA_CN_INFO"
echo -e "\t\tEmail Address\t\t\t: $CA_EMAIL_INFO"
echo -e "\t\tCertificate Validity\t\t: $CA_CERT_DAYS days"
}

function status_check() {
LAST_STATUS="$?"
if [ "$LAST_STATUS" -ne 0 ]; then
  echo -e "$1\n"
  exit
fi
}

function root_check() {
if [ "$(id -u)" != "0" ]; then
   echo -e "\nThis script must be run as root. Exiting for now.\n" 1>&2
   exit 1
fi
}

function main() {
if [ ! -d "$PWD/certs/ca_certs" ]; then
  mkdir -p "$PWD/certs/ca_certs/"
  status_check "Unable to create $PWD/certs/ca_certs directory, check Permissions or path"
else
  read -r -p "$PWD/certs/ca_certs directory contains old data would you like to clear its contents?  [Y/N] : " CA_DIR_INPUT
  if [ "$CA_DIR_INPUT" == "Y" ] || [ "$CA_DIR_INPUT" == "y" ]; then
    rm -rf "$PWD/certs/ca_certs/*"
    status_check "Unable to delete contents of $PWD/certs/ca_certs, check Permissions or path"
  else
    echo "\nWARNING: $PWD/certs/ca_certs directory exists, there might be unknown issues while generating CA certs.\n"
  fi
fi
read_cert_details

echo -e "\nGenerating new CA Private key\n"
openssl genrsa -out "$PWD/certs/ca_certs/ca-private.key" 2048 >/dev/null 2>&1
status_check "Something went wrong while executing command 'openssl genrsa -out $PWD/certs/ca_certs/ca-private.key 2048'"

echo -e "Generating new CA Cert for $CA_CERT_DAYS days\n"
openssl req -new -x509 -days "$CA_CERT_DAYS" -nodes -key "$PWD/certs/ca_certs/ca-private.key" -sha256 -out "$PWD/certs/ca_certs/ca-cert.pem" -config "$PWD/certs/ca_certs/ca-setup.conf"
status_check "Something went wrong while executing command 'openssl req -new -x509 -days $CA_CERT_DAYS -nodes -key $PWD/certs/ca_certs/ca-private.key -sha256 -out $PWD/certs/ca_certs/ca-cert.pem -config $PWD/certs/ca_certs/ca-setup.conf'"

echo -e "Successfully generated CA certs, please find the below details\n"
echo -e "CA Cert \t\t: $PWD/certs/ca_certs/ca-cert.pem"
echo -e "CA Private Key \t\t: $PWD/certs/ca_certs/ca-private.key\n"
}

root_check
main
