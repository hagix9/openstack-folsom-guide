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
### Public Network ###########################################
##############################################################

# Name of External Network :
EXT_NET_NAME=ext-net

# External Network :
EXT_NET_CIDR="192.168.1.128/24"
EXT_NET_LEN=${EXT_NET_CIDR#*/}

# External bridge that we have configured into l3_agent.ini :
EXT_NET_BRIDGE=br-ex

# IP of external bridge (br-ex) :
EXT_GW_IP="192.168.1.168"

# IP of the Public Network Gateway (i.e.external router) :
EXT_NET_GATEWAY="192.168.1.1"

# Floating IP range :
POOL_FLOATING_START="192.168.1.130"
POOL_FLOATING_END="192.168.1.150"

###############################################################

# Function to get ID :
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
    local ext_net_cidr="$2"
    local ext_net_gateway="$4"
    local pool_floating_start="$5"
    local pool_floating_end="$6"

    ext_net_id=$(get_id quantum net-create $ext_net_name -- --router:external=True)
    quantum subnet-create --ip_version 4 --allocation-pool start=$pool_floating_start,end=$pool_floating_end \
    --gateway $ext_net_gateway $ext_net_id $ext_net_cidr -- --enable_dhcp=False
}

# Connect the Tenant Virtual Router to External Network :
connectTenantRoutertoExternalNetwork() {
    local router_name="$1"
    local ext_net_name="$2"

    router_id=$(get_id quantum router-show $router_name)
    ext_net_id=$(get_id quantum net-show $ext_net_name)
    quantum router-gateway-set $router_id $ext_net_id
}


create_net $TENANT_NAME $NETWORK_NAME $ROUTER_NAME $FIXED_RANGE $NETWORK_GATEWAY
create_ext_net $EXT_NET_NAME $EXT_NET_CIDR $EXT_NET_BRIDGE $EXT_NET_GATEWAY $POOL_FLOATING_START $POOL_FLOATING_END
connectTenantRoutertoExternalNetwork $ROUTER_NAME $EXT_NET_NAME

# Configure br-ex to reach public network :
ip addr add $EXT_GW_IP/$EXT_NET_LEN dev $EXT_NET_BRIDGE
ip link set $EXT_NET_BRIDGE up
