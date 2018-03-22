#!/bin/bash

#set -x
set -e

INTERACTIVE=0
IP=""
while getopts "ia:" opt; do
    case "$opt" in
    i) INTERACTIVE=1
       ;;
    a) IP=$OPTARG
       ;;
    *) echo "usage: -i -a [ADDRESS]"
       exit 0
       ;;
    esac
done

create_ingress() {
    sed -e "s/%NAME/$1/g" -e "s/%HOST/$2/g" -e "s/%IP/$3/g" test-fanout-ingress.yaml | kubectl create -f -
}

create_deployment() {
    sed -e "s/%NAME/$1/g" -e "s/%NUM/$2/g" test.yaml | kubectl create -f -
}

create_service() {
    sed -e "s/%NAME/$1/g" test-svc.yaml | kubectl create -f -
}

delete_ingress() {
    sed -e "s/%NAME/$1/g" -e "s/%HOST/$2/g" test-fanout-ingress.yaml | kubectl delete -f -
}

delete_deployment() {
    sed -e "s/%NAME/$1/g" -e "s/%NUM/$2/g" test.yaml | kubectl delete -f -
}

delete_service() {
    sed -e "s/%NAME/$1/g" test-svc.yaml | kubectl delete -f -
}

scale_deployment() {
    sed -e "s/%NAME/$1/g" -e "s/%NUM/$2/g" test.yaml | kubectl apply -f -
}

create_secrets() {
    KEY="/tmp/tls.key"
    CRT="/tmp/tls.crt"

    openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout ${KEY} -out ${CRT} -subj "/CN=${1}"
    kubectl create secret tls ${1} --key ${KEY} --cert ${CRT}

    rm ${KEY}
    rm ${CRT}
}

delete_secrets() {
    kubectl delete secret tls ${1}
}

declare -a HOSTS
HOSTS=(foo.example.com bar.example.com baz.example.com qux.example.com corge.example.com thud.example.com)
INDEXES="0 1 2 3 4 5"

while true
do
    for i in $INDEXES
    do
        create_deployment $i 10
    done
    if [ $INTERACTIVE == 1 ]
    then
        echo Continue
        read y
    fi

    for i in $INDEXES
    do
        create_service $i
    done
    if [ $INTERACTIVE == 1 ]
    then
        echo Continue
        read y
    fi

    for i in $INDEXES
    do
        create_ingress $i ${HOSTS[$i]} $IP
    done
    if [ $INTERACTIVE == 1 ]
    then
        echo Continue
        read y
    else
        echo "waiting for pods"
        sleep 60
    fi

    for i in $INDEXES
    do
        scale_deployment $i 1
    done

    if [ $INTERACTIVE == 1 ]
    then
        echo Continue
        read y
    else
        echo "waiting for scaling"
        sleep 30
    fi

    for i in $INDEXES
    do
        scale_deployment $i 5
    done

    if [ $INTERACTIVE == 1 ]
    then
        echo Continue
        read y
    else
        echo "waiting for scale completion"
        sleep 30
    fi

    for i in $INDEXES
    do
        delete_deployment $i 5
        delete_service $i
        delete_ingress $i ${HOSTS[$i]}
    done

    echo "cleaned"
    if [ $INTERACTIVE == 1 ]
    then
        echo Continue
        read y
    else
        echo "Ctlr-C now to stop in clean state"
        sleep 15
    fi
done
