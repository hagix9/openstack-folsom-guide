#!/bin/sh
#
# Quantum Networking
#
# Description: Create Virtual Networking for Quantum
#
# Authors : 
# Emilien Macchi / StackOps
# Endre Karlson / Bouvet ASA
#
# Inspired by DevStack script
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0

###########################
### Private Network #######
###########################
TENANT_NAME="demo"
NETWORK_NAME="demo-net"
ROUTER_NAME="demo-router"
FIXED_RANGE="10.5.5.0/24"
NETWORK_GATEWAY="10.5.5.1"
###########################



##############################################################
### Public Network ############################################
# We use one floating range attached on one external bridge : #
###############################################################
EXT_NET_NAME=ext-net
EXT_NET_RANGE="192.168.1.128/25"
EXT_NET_NETMASK="24"
EXT_NET_BRIDGE=br-ex
# IP of the Public Network Gateway (i.e.external router) :
EXT_NET_GATEWAY="192.168.1.254"
###############################################################

get_id () {
        echo `$@ | awk '/ id / { print $4 }'`
}


# Create the Tenant private network :
create_net() {
    local tenant_name="$1"
    local network_name="$2"
    local router_name="$3"
    local fixed_range="$4"
    local network_gateway="$5"
    local tenant_id=$(keystone tenant-list | grep " $tenant_name " | awk '{print $2}')

    net_id=$(get_id quantum net-create --tenant_id $tenant_id $network_name)
    subnet_id=$(get_id quantum subnet-create --tenant_id $tenant_id --ip_version 4 $net_id $fixed_range --gateway_ip $network_gateway)
    router_id=$(get_id quantum router-create --tenant_id $tenant_id $router_name)
    quantum router-interface-add $router_id $subnet_id
}

# Create External Network :
create_ext_net() {
    local ext_net_name="$1"
    local ext_net_range="$2"
    local ext_net_gateway="$4"

    ext_net_id=$(get_id quantum net-create $ext_net_name -- --router:external=True)
    quantum subnet-create --ip_version 4 $ext_net_id $ext_net_range --gateway_ip $ext_net_gateway --enable_dhcp=False
}

# Connect the Tenant Virtual Router to External Network :
connect_TenantRouter_to_ExternalNetwork() {
    local router_name="$1"
    local ext_net_name="$2"

    router_id=$(get_id quantum router-show $router_name)
    ext_net_id=$(get_id quantum net-show $ext_net_name)
    quantum router-gateway-set $router_id $ext_net_id
}

ext_net_gw_ip() {
    local ext_net_name="$1"

    subnet_id=$(quantum net-show $ext_net_name | awk '/ subnets / {print $4}')
    echo $(quantum subnet-show $subnet_id | awk '/ allocation_pools / {print $5}' | cut -d\" -f2)
}

create_net $TENANT_NAME $NETWORK_NAME $ROUTER_NAME $FIXED_RANGE $NETWORK_GATEWAY
create_ext_net $EXT_NET_NAME $EXT_NET_RANGE $EXT_NET_BRIDGE $EXT_NET_GATEWAY
connect_TenantRouter_to_ExternalNetwork $ROUTER_NAME $EXT_NET_NAME

EXT_GW_IP=$(ext_net_gw_ip $EXT_NET_NAME)
CIDR_LEN=${EXT_NET_RANGE#*/}

# Configure br-ex to reach public network :
ip addr add $EXT_GW_IP/$EXT_NET_NETMASK dev $EXT_NET_BRIDGE
ip link set $EXT_NET_BRIDGE up
