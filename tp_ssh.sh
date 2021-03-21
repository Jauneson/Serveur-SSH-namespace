#!/bin/bash

echo "You must have root privileges to execute this script"
apt update
apt install ssh
rm /etc/ssh/sshd_config
echo "#	$OpenBSD: sshd_config,v 1.103 2018/04/09 20:41:22 tj Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/bin:/bin:/usr/sbin:/sbin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile	.ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of \"PermitRootLogin without-password\".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem	sftp	/usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	X11Forwarding no
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server
" > /etc/ssh/sshd_config

echo " restarting ssh services ..."
systemctl restart ssh.service
systemctl restart sshd.service
echo "configuring namespace for ssh..."
ip netns add servSSH
ip netns exec servSSH ip link set lo up
ip link add veth0 type veth peer name veth1
ip link set veth1 netns servSSH
ip netns exec servSSH ip addr add 192.168.2.2/24 dev veth1 
ip netns exec servSSH ip link set dev veth1 up
ip addr add 192.168.2.1/24 dev veth0
ip link set dev veth0 up
ip netns exec servSSH route add default gw 192.168.2.1 
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE 
sysctl -w net.ipv4.ip_forward=1
ip netns exec servSSH sshd.service
echo "done configuring namespace"
echo "limiting ram usage ..."
mkdir /sys/fs/cgroup/memory/servSSH
pgrep sshd > /sys/fs/cgroup/memory/servSSH/cgroup.procs
echo 1 000 000 000 > /sys/fs/cgroup/memory/servSSH/memory.max_usage_in_bytes
echo "limiting CPU usage..."
mkdir /sys/fs/cgroup/cpu/servSSH
pgrep sshd > /sys/fs/cgroup/cpu/servSSH/cgroup.procs
echo "1000000" > /sys/fs/cgroup/cpu/servSSH/cpu.cfs_period_us
echo "400000" > /sys/fs/cgroup/cpu/servSSH/cpu.cfs_quota_us
echo "Cgroup configured. SSHD is now running in his own namespace, and is limited to 1 GB of ram and 40% of CPU"