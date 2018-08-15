#! /bin/bash
function read_cert_details() {
echo ""
while [ -z $CERT_COUNTRY_INFO ]; do read -p "Provide Country Code (2 Letters) [IN] : " CERT_COUNTRY_INFO; done
while [ -z $CERT_STATE_INFO ]; do read -p "Provide State Information : " CERT_STATE_INFO; done
while [ -z $CERT_CITY_INFO ]; do read -p "Provide City Information : " CERT_CITY_INFO; done
while [ -z $CERT_ORG_INFO ]; do read -p "Provide Organization Name : " CERT_ORG_INFO; done
while [ -z $CERT_DEPT_INFO ]; do read -p "Provide Department Information : " CERT_DEPT_INFO; done
while [ -z $CERT_EMAIL_INFO ]; do read -p "Provide Email Address : " CERT_EMAIL_INFO; done
while [ -z $CERT_VALID_DAYS ]; do read -p "How many days would you like the $NAME_VALUE cert to be valid for? [DAYS] : " CERT_VALID_DAYS && validate_days; done
show_cert_details
echo ""
read -p "Would you like to proceed with the above selection [Y/N] " READ_INPUT
if [ "$READ_INPUT" == "Y" -o "$READ_INPUT" == "y" ]; then
  write_csr_file
  [ "$ALT_NAMES" -eq 1 ] &&  san_conf_file
else
  echo -e "\nBased on input receieved, exiting now\n"
  exit
fi
}

function validate_days() {
if ! [[ $CERT_VALID_DAYS =~ ^[0-9]+$ ]]; then
  CERT_VALID_DAYS=$(echo $CERT_VALID_DAYS | bc)
  if [[ $CERT_VALID_DAYS -lt 1 ]]; then
    read -r -p "How many days would you like the $NAME_VALUE cert to be valid for? [DAYS] : " CERT_VALID_DAYS
    CERT_VALID_DAYS=$(echo $CERT_VALID_DAYS | bc)
    validate_days
  fi
fi
}

function write_csr_file() {
cat > $PWD/certs/$NAME_VALUE/$NAME_VALUE-csr.conf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C = $CERT_COUNTRY_INFO
ST = $CERT_STATE_INFO
L = $CERT_CITY_INFO
O = $CERT_ORG_INFO
OU = $CERT_DEPT_INFO
emailAddress = $CERT_EMAIL_INFO
CN = $NAME_VALUE
EOF
}

function san_conf_file(){
cat > $PWD/certs/$NAME_VALUE/$NAME_VALUE-v3.conf << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $NAME_VALUE
EOF
for i in $(seq $SAN_HOSTS_COUNT); do
  n=$(echo "$i"+1 | bc)
  echo "DNS.$n = $(echo "$SAN_HOSTS_VALUE" | cut -d "," -f$i)" >> $PWD/certs/$NAME_VALUE/$NAME_VALUE-v3.conf
done
}

function show_cert_details() {
echo -e "\nPer your selection below are the details entered\n"
echo -e "\t\tCountry Code\t\t\t: $CERT_COUNTRY_INFO"
echo -e "\t\tState Information\t\t: $CERT_STATE_INFO"
echo -e "\t\tCity\t\t\t\t: $CERT_CITY_INFO"
echo -e "\t\tOrganization\t\t\t: $CERT_ORG_INFO"
echo -e "\t\tDepartment\t\t\t: $CERT_DEPT_INFO"
echo -e "\t\tCommon Name\t\t\t: $NAME_VALUE"
echo -e "\t\tEmail Address\t\t\t: $CERT_EMAIL_INFO"
echo -e "\t\tCertificate Validity\t\t: $CERT_VALID_DAYS days"
}

function status_check() {
LAST_STATUS=$(echo $?)
if [ "$LAST_STATUS" -ne 0 ]; then
  echo -e "$1\n"
  exit
fi
}

function root_check() {
# Ensure that only root user can excute this script
if [ "$(id -u)" != "0" ]; then
   echo -e "\nThis script must be run as root. Exiting for now.\n" 1>&2
   exit 1
fi
}

function check_hostname() {
# check if hostname is a valid FQDN
echo "$1" | grep -E '^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$' >/dev/null 2>&1
VALID_NAME=$(echo $?)
if [ "$1" == "localhost" ] || [ "$1" == "localhost.localdomain" ] || [ "$VALID_NAME" != 0 ]; then
   echo -e "\nProvided Hostname is Invalid"
   usage
   exit
fi
}

function create_cert_directory() {
if [ ! -d $PWD/certs/$NAME_VALUE ]; then
  mkdir -p $PWD/certs/$NAME_VALUE
  status_check "Unable to create $PWD/certs/$NAME_VALUE directory, check Permissions or path"
else
  rm -rf $PWD/certs/$NAME_VALUE/*
  status_check "Unable to delete contents of $PWD/certs/$NAME_VALUE, check Permissions or path"
fi
}

function process_name_args() {
PARSE_NAME_OPTION=$(echo "$1" | cut -d "=" -f1)
if [ "$PARSE_NAME_OPTION" != "--name" ]; then
  echo -e "\nInvalid arguments passed, exiting now\n"
  usage
  exit
else
  NAME_VALUE=$(echo "$1" | cut -d "=" -f2)
  check_hostname "$NAME_VALUE"
  create_cert_directory
fi
}

function check_script_args() {
if [ "$#" -eq 2 ]; then
  SAN_HOSTS_COUNT=$(echo $(echo "$2" | tr -dc , | wc -c)+1  | bc )
  PARSE_SAN_OPTION=$(echo "$2" | cut -d "=" -f1)
  if [ "$PARSE_SAN_OPTION" == "--sub-alt-names" ]; then
    process_name_args "$1"
    ALT_NAMES=1
    SAN_HOSTS_VALUE=$(echo "$2" | cut -d "=" -f2)
  else
    echo -e "\nInvalid arguments passed, exiting now\n"
    usage
    exit
  fi
fi
if [ "$#" -eq 1 ]; then
  process_name_args "$1"
  ALT_NAMES=0
fi
}

function usage() {
echo -e "\nGenerate SSL certs using this script\n"
echo -e "\t-h or --help\t\t Help options"
echo -e "\t--name\t\t\t Name of the server that certificate is generated for (Mandatory)"
echo -e "\t--sub-alt-names\t\t Subject Alternative Names followed by a comma (,)"
echo -e "\nUsage:  bash $0 --name=server.example.com --sub-alt-names=host.example.net,myserver.lab.local\n"
}

function main()
{
if [ ! -f "$PWD/certs/ca_certs/ca-cert.pem" ] && [ ! -f "$PWD/certs/ca_certs/ca-private.key" ]; then
  echo -e "\nUnable to read CA Certs, Please execute 'generate-ca.sh script to generate CA certs and then re-run this script'\nExiting Now!!\n"
  exit
fi
read_cert_details

# Generating CSR for $NAME_VALUE
echo -e "\nGenerating Private Key and CSR for $NAME_VALUE\n"
openssl req -new -nodes -out $PWD/certs/$NAME_VALUE/$NAME_VALUE.csr -keyout $PWD/certs/$NAME_VALUE/$NAME_VALUE.key -config $PWD/certs/$NAME_VALUE/$NAME_VALUE-csr.conf >/dev/null 2>&1
status_check "Something went wrong while executing command 'openssl req -new -nodes -out $PWD/certs/$NAME_VALUE/$NAME_VALUE.csr -keyout $PWD/certs/$NAME_VALUE/$NAME_VALUE.key -config $PWD/certs/$NAME_VALUE/$NAME_VALUE-csr.conf'"

openssl x509 -req -in $PWD/certs/$NAME_VALUE/$NAME_VALUE.csr -CA $PWD/certs/ca_certs/ca-cert.pem -CAkey $PWD/certs/ca_certs/ca-private.key -CAcreateserial -out $PWD/certs/$NAME_VALUE/$NAME_VALUE.crt -extfile $PWD/certs/$NAME_VALUE/$NAME_VALUE-v3.conf >/dev/null 2>&1
status_check "Something went wrong while executing command 'openssl x509 -req -in $PWD/certs/$NAME_VALUE/$NAME_VALUE.csr -CA $PWD/certs/ca_certs/ca-cert.pem -CAkey $PWD/certs/ca_certs/ca-private.key -CAcreateserial -out $PWD/certs/$NAME_VALUE/$NAME_VALUE.crt -extfile $PWD/certs/$NAME_VALUE/$NAME_VALUE-v3.conf'"

echo -e "Successfully generated certs for $NAME_VALUE, please find the below details\n"
echo -e "CA Cert \t\t: $PWD/certs/ca_certs/ca-cert.pem"
echo -e "Signed Cert \t\t: $PWD/certs/$NAME_VALUE/$NAME_VALUE.crt"
echo -e "Private KeyFile \t: $PWD/certs/$NAME_VALUE/$NAME_VALUE.key"
echo -e "CSR File \t\t: $PWD/certs/$NAME_VALUE/$NAME_VALUE.csr\n"
}

root_check
if [ "$#" -eq 2 ]; then
  check_script_args "$1" "$2"
elif [ "$#" -eq 1 ]; then
  check_script_args "$1"
else
  usage
  exit
fi
main
