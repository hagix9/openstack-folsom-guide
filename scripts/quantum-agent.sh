#!/bin/sh
#
# Launch Quantum Agent
#
# Emilien Macchi
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#

HOME=/etc/quantum
quantum-openvswitch-agent --log-file=/var/log/quantum/quantum-agent.log>> /dev/null 2>&1 &
