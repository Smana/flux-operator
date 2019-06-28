#!/bin/bash

# Text color variables
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgre=${txtbld}$(tput setaf 2) #  green
bldylw=${txtbld}$(tput setaf 3) #  yellow
txtrst=$(tput sgr0)             # Reset
err=${bldred}ERROR${txtrst}
info=${bldgre}INFO${txtrst}
warn=${bldylw}WARNING${txtrst}

if [[ -z ${1} ]]; then
    echo -e " ${err}: First argument required: The secret name that contains the tiller certificate"
    exit 1
elif ! $(kubectl get secret ${1} &>/dev/null); then
    echo -e "${err}: secret ${1} doesn't exist"
    exit 1
fi

DATA_JSON=$(kubectl get secret -o json ${1} | jq -r '{data}')

TMPDIR=$(mktemp -d)

for FILE in ca.crt tls.crt tls.key; do
    echo ${DATA_JSON} | jq  -r '.data['\"${FILE}\"']' | base64 -d > ${TMPDIR}/${FILE}
done

echo -e "${info}: Tiller certs have been saved in the directory ${TMPDIR}\n"
tree ${TMPDIR}

echo -e "kubectl create secret generic -n flux tiller-secret --from-file=${TMPDIR}/tls.crt --from-file=${TMPDIR}/tls.key --from-file=${TMPDIR}/ca.crt"

echo -e "${info}: You can run the following command to initialize Tiller:\n"
echo -e "helm init --service-account=tiller --tiller-namespace=flux \ "
echo -e "--tiller-tls --tiller-tls-cert=${TMPDIR}/tls.crt --tiller-tls-key=${TMPDIR}/tls.key --tls-ca-cert=${TMPDIR}/ca.crt \ "
echo -e "--tiller-tls-verify --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}'"
