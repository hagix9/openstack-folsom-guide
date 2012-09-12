#!/bin/sh
#
# Quantum Networking
#
# Description: Create Virtual Networking fro Quantum
#
# Author : Emilien Macchi / StackOps
#
# Inspired by DevStack script
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#


FLOATING_RANGE="192.168.0.128/25"
FIXED_RANGE="10.5.5.0/24"
NETWORK_GATEWAY="10.5.5.2"


PUBLIC_BRIDGE=br-ex
TENANT_ID=$(keystone tenant-list | grep " demo " | awk '{print $2}')

NET_ID=$(quantum net-create --tenant_id $TENANT_ID demo-net | grep ' id ' | awk '{print $4}')
SUBNET_ID=$(quantum subnet-create --tenant_id $TENANT_ID --ip_version 4 --gateway $NETWORK_GATEWAY $NET_ID $FIXED_RANGE | grep ' id ' | awk '{print $4}')
ROUTER_ID=$(quantum router-create --tenant_id $TENANT_ID demo-router | grep ' id ' | awk '{print $4}')
quantum router-interface-add $ROUTER_ID $SUBNET_ID

EXT_NET_ID=$(quantum net-create ext_net -- --router:external=True | grep ' id ' | awk '{print $4}')
EXT_GW_IP=$(quantum subnet-create --ip_version 4 $EXT_NET_ID $FLOATING_RANGE -- --enable_dhcp=False | grep 'gateway_ip' | awk '{print $4}')
quantum router-gateway-set $ROUTER_ID $EXT_NET_ID
CIDR_LEN=${FLOATING_RANGE#*/}
ip addr add $EXT_GW_IP/$CIDR_LEN dev $PUBLIC_BRIDGE
ip link set $PUBLIC_BRIDGE up
