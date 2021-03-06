#!/bin/bash

set -e
set -x

trap cleanup 0 1

cleanup() {
	oc get co || true
	oc get clusterversion || true
	oc get nodes || true
	oc get pods -n openshift-sriov-network-operator || true
	popd
}

if [ -d plow ]; then
        rm -rf plow
fi

git clone https://github.com/cloud-bulldozer/plow.git

pushd openshift-baremetal-ci/tests/sriov

# ./apply-performance-conf.sh

sleep 20

export SUBSCRIPTION=true
./run-sriov-operator.sh

sleep 20

# Create my-ripsaw namespace so that net-attach-def
# can be created in that namespace
oc create ns my-ripsaw || true

oc create -f templates/ripsaw-client-nad.yaml
oc create -f templates/ripsaw-server-nad.yaml

popd

#  For internal machines we have an ES server to warehouse the results from each run. 
export ES_PORT=9200
export ES_SERVER=perf-sm5039-4-5.perf.lab.eng.rdu2.redhat.com

export MULTUS_CLIENT_NAD=my-ripsaw/client-nad
export MULTUS_SERVER_NAD=my-ripsaw/server-nad

pushd plow/workloads/network-perf/
echo "running perf multus network test"
./run_multus_network_tests_fromgit.sh ovn-baremetal-ci
