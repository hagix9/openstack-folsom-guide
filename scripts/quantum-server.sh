unch Quantum Server
#
# Emilien Macchi
#
# Support: openstack@lists.launchpad.net
# License: Apache Software License (ASL) 2.0
#

HOME=/etc/quantum
sudo -u quantum quantum-server --log-file=/var/log/quantum/quantum-server.log>/dev/null&
