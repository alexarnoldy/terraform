#!/bin/bash 

## Script to run Terraform to create an openSUSE JeOS cluster on the local system 
## then run K3sup to create a K3s cluster on it, and finally import the cluster 
## into a Rancher server instance.

## 02/17/2021 - alex.arnoldy@suse.com

################################################################################################
##		This script relies on /etc/hosts to define the simulated edge locations, for 
##		IPAM, hostname resolution, vcpu & memory specs and cluster labels
## IMPORTANT: 	Ensure /etc/hosts is configured to resolve hostnames in the format
## 		of "edge-location"-server-[0-2] and "edge-location"-agent-[0-N]
##		i.e. bangkok-server-0 and bangkok-agent-5
################################################################################################
##		    Using this script to deploy HA server nodes requires a load balancer 
## SUPER IMPORTANT: for the Kubernetes API server, port 6443
################################################################################################

## The Rancher server is identified in the rancher2.tf file
## Rancher tokens need to be kept in a ~/.rancher_tokens file in this user's home directory
## Format needs to be:
## export RANCHER_ACCESS_KEY=token-xxxxx
## export RANCHER_SECRET_KEY=xxxxxxxxxxxxxxxx
source ${HOME}/.rancher_tokens

RED='\033[0;31m'
LCYAN='\033[1;36m'
NC='\033[0m' # No Color
EDGE_LOCATION=$1
SSH_USER="ec2-user"
CONFIG_FILE="./k3s_edge_sandbox.conf"
INSTALLED_K3s_VERSION="v1.20.4+k3s1"


## Test for at least one argument provided with the command
[ -z "$1" ] && echo "Usage: k3s-cluster-create.sh  <name of predefined edge location>  <Optional domain name>" && exit


## Ensure the required utilities are present before continuing
for UTILITY in nc git terraform k3sup kubectl 
do
	which ${UTILITY} &> /dev/null || { echo "The ${UTILITY} utility is not in your path or is not present on this system. Please resolve before attempting another run. Exiting."; exit; }
done


## Set DOMAIN_NAME to second argument, if provided
[ -z "$2" ] && DOMAIN_NAME=[A-Za-b0-9] || DOMAIN_NAME=$2


## Set EDITOR to vi, if not set
#[ -z "$EDITOR" ] && export EDITOR=vi


## Discover up to 3 server nodes to be used in this edge location.
## Note that the array is populated with the IP addresses being the even indices
## and the associated hostnames being the subsequent odd indices
## i.e. ${ALL_SERVERS[0]} is the IP of the first server and ${ALL_SERVERS[1]} is
## the hostname of the first server
ALL_SERVERS=($(grep -iw ${EDGE_LOCATION} ${CONFIG_FILE} | grep -i ${DOMAIN_NAME} | grep -i server | awk -F# '{print$1}' | sort -k 1,1))
#ALL_SERVERS=($(getent hosts | grep -iw ${EDGE_LOCATION} | grep -i ${DOMAIN_NAME} | grep -i server | sort -k 1,1))



## FIRST_SERVER_HOSTNAME will used in the following test and later in the script
FIRST_SERVER_HOSTNAME=${ALL_SERVERS[1]}
VPC_CIDR=${ALL_SERVERS[0]}

## Test to see if the provided argument matches a defined edge location
[ -z "${FIRST_SERVER_HOSTNAME}" ]  && echo -e "Edge location \"${LCYAN}${EDGE_LOCATION}${NC}\" is not defined." && exit


## Discover up to 25 agent nodes to be used in this edge location. Adjust above 25 as needed.
ALL_AGENTS=($(grep -iw ${EDGE_LOCATION} ${CONFIG_FILE} | grep -i ${DOMAIN_NAME} | grep -i agent | awk -F# '{print$1}' | sort -k 1,1))
#ALL_AGENTS=($(getent hosts | grep -iw ${EDGE_LOCATION} | grep -i ${DOMAIN_NAME} | grep -i agent | sort -k 1,1))


## Establish the last index in the arrays
FINAL_AGENT_INDEX=$(echo $((${#ALL_AGENTS[@]}-1)))
FINAL_SERVER_INDEX=$(echo $((${#ALL_SERVERS[@]}-1)))

## Establish the number of servers and agents in the arrays:
NUM_SERVERS=$(echo $((${#ALL_SERVERS[@]} / 2 )))
NUM_AGENTS=$(echo $((${#ALL_AGENTS[@]} / 2 )))


## SERVER_INSTANCE_TYPE and AGENT_ALLOCATION are arrays where the first element (0) is vcpu and second 
## element (1) is memory. These are taken from the first server and first agent entry for the 
## edge location in /etc/hosts
SERVER_INSTANCE_TYPE=($(grep ${ALL_SERVERS[1]} /etc/hosts | awk -F# '{print$2}'))
## Set AGENT_ALLOCATION only if there are agents specified
[ ${#ALL_AGENTS[@]} -gt 0 ] && AGENT_ALLOCATION=($(grep ${ALL_AGENTS[1]} /etc/hosts | awk -F# '{print$2}'))


##Example of how to iterate over the IPs in the array
#for INDEX in $(seq 0 2 ${FINAL_AGENT_INDEX}); do echo ${ALL_AGENTS[INDEX]}; done
##Example of how to iterate over the hostnames in the array
#for INDEX in $(seq 1 2 ${FINAL_AGENT_INDEX}); do echo ${ALL_AGENTS[INDEX]}; done


## Create the JeOS cluster nodes. Saves the state files to specific locations to keep things tidy
## Determine the CIDR denoted SUBNET based on the IP address of the first server
SUBNET=$(echo ${ALL_SERVERS[0]} | awk -F. '{print$1"."$2"."$3".0/24"}')

## Exctract the cluster_labels
CLUSTER_LABELS=$(grep ${ALL_SERVERS[1]} /etc/hosts | awk -F"labels: " '{print$2}')


## Create a custom tfvars file for this deployment
mkdir -p state/${EDGE_LOCATION}/
cat <<EOF> state/${EDGE_LOCATION}/${EDGE_LOCATION}.tfvars
instance_count = ${NUM_SERVERS}
${SERVER_INSTANCE_TYPE[0]}
#${SERVER_INSTANCE_TYPE[1]}
#k3s_agents = ${NUM_AGENTS}
#${AGENT_ALLOCATION[0]}
#${AGENT_ALLOCATION[1]}
edge_location = "${EDGE_LOCATION}"
#vpc_cidr = ${VPC_CIDR}
cluster_labels = {${CLUSTER_LABELS}}
EOF

terraform apply -auto-approve --state=state/${EDGE_LOCATION}/${EDGE_LOCATION}.tfstate -var-file=terraform.tfvars -var-file=state/${EDGE_LOCATION}/${EDGE_LOCATION}.tfvars

ALL_SERVER_PUBLIC_IPS=($(terraform output -state=state/${EDGE_LOCATION}/${EDGE_LOCATION}.tfstate ec2_instance_public_ips | egrep -v "\[|\]" | awk -F\, '{print$1}' | sed 's/\"//g'))
#echo ${ALL_SERVER_PUBLIC_IPS[@]}
FIRST_SERVER_PUBLIC_IP=$(echo ${ALL_SERVER_PUBLIC_IPS[0]})
#echo ${FIRST_SERVER_PUBLIC_IP}

ALL_SERVER_PRIVATE_IPS=($(terraform output -state=state/${EDGE_LOCATION}/${EDGE_LOCATION}.tfstate ec2_instance_private_ips | egrep -v "\[|\]" | awk -F\, '{print$1}' | sed 's/\"//g'))
#echo ${ALL_SERVER_PRIVATE_IPS[@]}
FIRST_SERVER_PRIVATE_IP=$(echo ${ALL_SERVER_PRIVATE_IPS[0]})

mkdir -p ~/.kube/

## quick way to install first server:
# K3s_VERSION="v1.20.4+k3s1"; ssh ec2-user@54.153.109.143 sh -c "K3s_VERSION="v1.20.4+k3s1" ; curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3s_VERSION}' INSTALL_K3S_EXEC='server --cluster-init --write-kubeconfig-mode=644' sh -s -"


## Ensure the server node is updated and ready before installing K3s 
# Remove any previous entries for this node in the local known_hosts file
ssh-keygen -q -R ${FIRST_SERVER_PUBLIC_IP} -f ${HOME}/.ssh/known_hosts &> /dev/null

## This tests for a shutdown entry to be added to the last log, indicating the node has rebooted
# Disabling this test as AWS cloud instances don't automatically get updated and rebooted (though I could likely do it through cloud-init), and they seem to be very out-of-date so patching takes a long time
#until ssh -o StrictHostKeyChecking=no ${SSH_USER}@${FIRST_SERVER_PUBLIC_IP} last -x | grep shutdown &> /dev/null; do echo "Waiting for ${FIRST_SERVER_HOSTNAME} to boot up and update its software..." && sleep 30; done

## Test for sshd to come online after the reboot, then wait ten seconds more for the node to finish booting
until nc -zv ${FIRST_SERVER_PUBLIC_IP} 22 &> /dev/null; do echo "Waiting until ${FIRST_SERVER_HOSTNAME} finishes rebooting..." && sleep 5; done
echo "Waiting for someone who truly gets me..."
#sleep 10


## Remove a previous config file if it exists
rm -f ${HOME}/.kube/kubeconfig-${EDGE_LOCATION}

## Test to see if more than one server is specified
[ ${#ALL_SERVERS[@]} -gt 2 ] && CLUSTER="--cluster-init" || CLUSTER=""

## Install first server node
K3s_VERSION="v1.20.4+k3s1"; ssh -oStrictHostKeyChecking=no ${SSH_USER}@${FIRST_SERVER_PUBLIC_IP} "K3s_VERSION="v1.20.4+k3s1" ; curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3s_VERSION}' INSTALL_K3S_EXEC='server ${CLUSTER} --write-kubeconfig-mode=644' sh -s -"

## Need to add --tls-san ${FIRST_SERVER_PUBLIC_IP} for this to work correctly. Then it will fail if the first server gets a new public IP address
#scp ${SSH_USER}@${FIRST_SERVER_PUBLIC_IP}:/etc/rancher/k3s/k3s.yaml ${HOME}/.kube/kubeconfig-${EDGE_LOCATION}



## Use k3sup to install the first server node
#k3sup install --ip ${FIRST_SERVER_PUBLIC_IP} ${CLUSTER} --sudo --user ${SSH_USER} --local-path ${HOME}/.kube/kubeconfig-${EDGE_LOCATION} --context k3s-${EDGE_LOCATION}
## --k3s-channel doesn't work with k3sup v0.9.6	
#k3sup install --ip ${FIRST_SERVER_IP} ${CLUSTER} --sudo --user ${SSH_USER} --k3s-channel stable  --local-path ${HOME}/.kube/kubeconfig-${EDGE_LOCATION} --context k3s-${EDGE_LOCATION}



## Wait until the K3s server node is ready before joining the rest of the nodes
#export KUBECONFIG=${HOME}/.kube/kubeconfig-${EDGE_LOCATION}
#kubectl config set-context k3s-${EDGE_LOCATION}
ssh -q ${SSH_USER}@${FIRST_SERVER_PUBLIC_IP} "until kubectl get deployment -n kube-system coredns &> /dev/null; do echo "Waiting for the Kubernetes API server to respond..." && sleep 10; done"
sleep 5
ssh -q ${SSH_USER}@${FIRST_SERVER_PUBLIC_IP} "kubectl -n kube-system wait --for=condition=available --timeout=600s deployment/coredns"

## Join the remaining two server nodes to the cluster
	NODE_TOKEN=$(ssh ${SSH_USER}@${FIRST_SERVER_PUBLIC_IP} sudo cat /var/lib/rancher/k3s/server/node-token)


for INDEX in 1 2; do 
cat <<EOF> /tmp/${ALL_SERVER_PUBLIC_IPS[INDEX]}.sh
FIRST_SERVER_PRIVATE_IP=${FIRST_SERVER_PRIVATE_IP};
NODE_TOKEN=$(ssh ${SSH_USER}@${FIRST_SERVER_PUBLIC_IP} sudo cat /var/lib/rancher/k3s/server/node-token)
K3s_VERSION=${INSTALLED_K3s_VERSION};
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3s_VERSION} K3S_URL=https://${FIRST_SERVER_PRIVATE_IP}:6443 K3S_TOKEN=${NODE_TOKEN} K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC='server' sh -
EOF
	scp -q -o StrictHostKeyChecking=no /tmp/${ALL_SERVER_PUBLIC_IPS[INDEX]}.sh ${SSH_USER}@${ALL_SERVER_PUBLIC_IPS[INDEX]}:~/ 
	ssh -q -o StrictHostKeyChecking=no ${SSH_USER}@${ALL_SERVER_PUBLIC_IPS[INDEX]} "bash ~/${ALL_SERVER_PUBLIC_IPS[INDEX]}.sh"
	sleep 5
	rm /tmp/${ALL_SERVER_PUBLIC_IPS[INDEX]}.sh
done




exit

#### Disabled until I can separate the provisiong of server and agent nodes in ec2
## Join all agent nodes to the cluster
#for INDEX in $(seq 0 2 ${FINAL_AGENT_INDEX}); do 
#	k3sup join --ip ${ALL_AGENTS[INDEX]} --server-ip ${FIRST_SERVER_IP} --sudo --user ${SSH_USER} 
## --k3s-channel doesn't work with k3sup v0.9.6	
#	k3sup join --ip ${ALL_AGENTS[INDEX]} --server-ip ${FIRST_SERVER_IP} --sudo --user ${SSH_USER} --k3s-channel stable
#	sleep 5
#done



## Extract and apply the string to deploy the cattle-agent and fleet-agent
export KUBECONFIG=${HOME}/.kube/kubeconfig-${EDGE_LOCATION}
kubectl config use-context k3s-${EDGE_LOCATION}

CATTLE_AGENT_STRING=$(grep -w command ${PWD}/state/${EDGE_LOCATION}/${EDGE_LOCATION}.tfstate | head -1 | awk -F\"command\"\: '{print$2}' | sed -e 's/",//' -e 's/"//' | awk '{print$4}')

## Apply securely, or attempt insecurely if it fails (for any reason)
kubectl apply -f ${CATTLE_AGENT_STRING} || { curl --insecure -sfL ${CATTLE_AGENT_STRING} | kubectl apply -f -; }

###### This section was the original attempt to label the clusters
###### The new method adds a label map to the rancher2 resource (in the rancher2.tf file)
## Command before attempting to deal with self-signed certs on Rancher server (above)
#bash -c "$(grep -w command ${PWD}/state/${EDGE_LOCATION}/${EDGE_LOCATION}.tfstate | head -1 | awk -F\"command\"\: '{print$2}' | sed -e 's/",//' -e 's/"//')"

## Wait until the Fleet agent has deployed before continuing
#until kubectl get namespace fleet-system ; do echo "Waiting for fleet-system namespace to be created (normally about 2 minutes)" && sleep 60; done
#sleep 10
#kubectl -n fleet-system wait --for=condition=available --timeout=600s deployment/fleet-agent


## Apply labels to the Fleet cluster object (via the Rancher server cluster), as defined in /etc/hosts, 
## specified with a space separated list after "labels:" and following the vCPU and memory specs

## Find the cluster identity and namespace in the Rancher server cluster
#export KUBECONFIG=~/.kube/kubeconfig-rancher-server
#until kubectl get clusters.fleet.cattle.io -A | grep ${EDGE_LOCATION}; do echo "Waiting for fleet-manager" && sleep 10; done
#
#FLEET_CLUSTER=($(kubectl get clusters.fleet.cattle.io -A | grep ${EDGE_LOCATION}))
#CLUSTER_LABELS=($(grep ${ALL_SERVERS[1]} /etc/hosts | awk -F"labels: " '{print$2}'))
#FINAL_LABEL_INDEX=$(echo $((${#CLUSTER_LABELS[@]}-1)))
#
#echo "Show Fleet cluster object:"
#kubectl get clusters.fleet.cattle.io -A | grep ${EDGE_LOCATION}
#for INDEX in $(seq 0 1 ${FINAL_LABEL_INDEX}); do
#	kubectl label cluster.fleet.cattle.io ${FLEET_CLUSTER[1]} -n ${FLEET_CLUSTER[0]} ${CLUSTER_LABELS[INDEX]} 
#done
###### 

##Final messages for using and destroying the cluster
echo "export EDGE_LOCATION=${EDGE_LOCATION}; source ${HOME}/.rancher_tokens; terraform destroy -auto-approve --state=state/\${EDGE_LOCATION}/\${EDGE_LOCATION}.tfstate -var-file=terraform.tfvars -var-file=state/\${EDGE_LOCATION}/\${EDGE_LOCATION}.tfvars" > ./bin/destroy_${EDGE_LOCATION}_edge_location.sh

echo -e "######################## ${RED}TO DESTROY THIS CLUSTER, USE THE COMMAND:${LCYAN} ./bin/destroy_${EDGE_LOCATION}_edge_location.sh${NC} "
#echo -e "## ${LCYAN}export EDGE_LOCATION=${EDGE_LOCATION}; source ~/.rancher_tokens; terraform destroy -auto-approve --state=state/\${EDGE_LOCATION}/\${EDGE_LOCATION}.tfstate -var-file=terraform.tfvars -var-file=state/\${EDGE_LOCATION}/\${EDGE_LOCATION}.tfvars${NC}"
#echo "###########################################################################"
echo ""

chmod 755 ./bin/destroy_${EDGE_LOCATION}_edge_location.sh

echo ""; echo "It may take a few more minutes for the ${EDGE_LOCATION} cluster to finish getting ready for use."
echo ""; echo -e "Run the command sequence: \`${LCYAN}export EDGE_LOCATION=${EDGE_LOCATION}; export KUBECONFIG=${HOME}/.kube/kubeconfig-\${EDGE_LOCATION}; kubectl config set-context k3s-\${EDGE_LOCATION}${NC}\` to work with the k3s-${EDGE_LOCATION} cluster"
