#!/bin/bash

set -o errexit  # Exit the script with error if any of the commands fail

export PROJECT_DIRECTORY="$(pwd)"
NODE_ARTIFACTS_PATH="${PROJECT_DIRECTORY}/node-artifacts"
export NVM_DIR="${NODE_ARTIFACTS_PATH}/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# set up keytab
mkdir -p "$(pwd)/.evergreen"
touch "$(pwd)/.evergreen/krb5.conf.empty"
export KRB5_CONFIG="$(pwd)/.evergreen/krb5.conf.empty"
echo "Writing keytab"
# DON'T PRINT KEYTAB TO STDOUT
set +o verbose
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ${KRB5_KEYTAB} | base64 -D > "$(pwd)/.evergreen/drivers.keytab"
else
    echo ${KRB5_KEYTAB} | base64 -d > "$(pwd)/.evergreen/drivers.keytab"
fi
echo "Running kinit"
kinit -k -t "$(pwd)/.evergreen/drivers.keytab" -p ${KRB5_PRINCIPAL}

set -o xtrace
if [ -z ${NODE_VERSION+omitted} ]; then echo "NODE_VERSION is unset" && exit 1; fi
NODE_MAJOR_VERSION=$(echo "$NODE_VERSION" |  cut -d. -f1)
if [[ $NODE_MAJOR_VERSION -ge 12 ]]; then
  npm install kerberos@">=2.0.0-beta.0"
else
  npm install kerberos@"^1.1.7"
fi
set +o xtrace

npm run check:kerberos

# destroy ticket
kdestroy
