#!/bin/bash
#######################################################################################################################
#   Title:  Install LDAP-client
#   Author: Athanasius C. kebei
#
#   This script is based on information from the following links inter alias. 
#   https://access.redhat.com/documentation/en--US/Red_Hat_Enterprise_Linux/6/html/Deployment_Guide/ch Directory_Server# s.html#s2-ldap-#  installation
#   http://www.server-world.info/en/note?os=CentOS_6&p=ldap&f=2
#   http://docs.fedoraproject.org/en-US/Fedora/15/html/Deployment_Guide/chap-SSSD_User_Guide-# Introduction.html
#######################################################################################################################


#######################################################################################################################
# 		SECTION I: COMMUNICATION BETWEEN CLIENT AND LDAPSERVER AND NAME RESOLUTION
# LDAP depends a lot on name resolution. What is the FQDN of the ldapserver(s) we want rhel clients to authenticate to?
# Put them in the /etc/hosts file of the rhel ldap client. Also put the ip address and hostname of rhel client in its /etc/hosts file
#######################################################################################################################
# echo -e "$ip addr	$hostname     >> /etc/hosts
echo -e "#Rhel6.5 LDAP Servers" >> /etc/hosts
echo -e "192.168.1.35	ldapserver1.neustar.net" >> /etc/hosts
echo -e "192.168.1.36	ldapserver2.neustar.net" >> /etc/hosts

# If firewall is enabled on ldap server, Setup iptables before configuring sssd, so it can connect to the server. 
#  Uncomment appropriate lines. 636 is encrypted and 389 is not
# iptables -I OUTPUT -m state --state NEW -p tcp -d 192.168.1.35 --dport 636 -j ACCEPT
# iptables -I OUTPUT -m state --state NEW -p tcp -d 192.168.1.35 --dport 389 -j ACCEPT
# iptables -I OUTPUT -m state --state NEW -p tcp -d 192.168.1.36 --dport 636 -j ACCEPT
# iptables -I OUTPUT -m state --state NEW -p tcp -d 192.168.1.36 --dport 389 -j ACCEPT


#######################################################################################################################
#		SECTION II: LDAP PACKAGE CHECK AND INSTALLATION
# Check if all necessary packages to configure rhel server as ldap client are Installed. Install missing
# A repo (even a cdrom-based local one) has to be configured and working for this check to work). 
# sssd and openldap-clients are installed by default. Might need to uninstall if previously configured.
#######################################################################################################################

# Packages check and install
yum -y install sssd
yum -y install krb5-workstation
yum -y install krb5-libs
yum -y install pam_ldap
yum -y install nss-pam-ldapd
yum -y install libsss_sudo
yum -y install openldap-clients


#######################################################################################################################
#		SECTION III: Backup!
# Caution: Backup all configuration files that will be/maybe modified
######################################################################################################################
cp /etc/sysconfig/ldap /etc/sysconfig/ldap.preldap
cp /var/lib/ldap /var/lib/ldap.preldap
cp /etc/pam.d/smartcard-auth /etc/pam.d/smartcard-auth.preldap
cp /etc/pam.d/fingerprint-auth /etc/pam.d/fingerprint-auth.preldap
cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf.preldap.preldap
cp /etc/nsswitch.conf /etc/nsswitch.conf.preldap.preldap 
cp /etc/pam.d/password-auth /etc/pam.d/password-auth.preldap
cp /etc/pam.d/system-auth /etc/pam.d/system-auth.preldap
cp /etc/krb5.conf /etc/krb5.conf.preldap
cp /etc/ntp.conf /etc/ntp.conf.preldap
cp /etc/secuirty/access.conf /etc/secuirty/access.conf.preldap
cp /etc/sysconfig/authconfig /etc/sysconfig/authconfig.preldap
cp /etc/sysconfig/autofs /etc/sysconfig/autofs.preldap
cp /etc/passwd /etc/passwd.preldap
cp /etc/group	/etc/group.preldap


###############################################################################################################
#		SECTION IV: HOME DIRECTORIES 
# Set client up for NFS-based user home directory automounting Via AUTOFS 
###############################################################################################################
echo -e "/home	auto.home	-nobrowse" >> /etc/auto.master
echo -e "-	auto.direct		-nobrowse" >> /etc/automaster
echo -e "*	    nsfserver.neustar.net:/export/home/&" >> /etc/auto.home
chkconfig autofs on && service autofs start
mount -a


###############################################################################################################
#		SECTION V: LDAP SERVER CERTIFICATES
# If communication with ldap server is encrypted, Copy authentication certificates from ldap server to the client
###############################################################################################################

if [ ! -f /etc/openldap/cacerts/client.pem ];
then
    scp root@192.168.1.35:/etc/openldap/cacerts/client.pem /etc/openldap/cacerts/client.pem
fi

if [ ! -f /etc/openldap/cacerts/ca.crt ];
then
    scp root@10.100.0.55:/etc/openldap/cacerts/ca.crt /etc/openldap/cacerts/ca.crt
fi

/usr/sbin/cacertdir_rehash /etc/openldap/cacerts
chown -Rf root:ldap /etc/openldap/cacerts
chmod -Rf 750 /etc/openldap/cacerts
restorecon -R /etc/openldap/cacerts


#######################################################################################################################
#		SECTION VI: CONFIGURE SSSD
#######################################################################################################################
# Configure all relevant /etc files for sssd, ldap with authconfig.
authconfig --enablesssd --enablesssdauth --enablecachecreds --
enableldap --enableldaptls --enableldapauth --enableshadow --enablemkhomedir --enablelocauthorize --
ldapserver=ldaps://ldapserver1.neustar.net,ldaps://ldapserver2.neustar.net--
ldapbasedn=dc=neustar,dc=net-- 
ldaploadcacert=ldaps://ldapserver1.neustar.net:/etc/openldap/cacerts/client.pem,ldaps://ldapserver2.neustar:/etc/openldap/cacerts/server.client.pem --
disablenis --disablekrb5 --updateall

# Add these settings to the [domain/default] section of /etc/sssd/sssd.conf:
# For troubleshooting if you need to expire cache right away
cat > /etc/sssd/sssd.conf << EOF
[sssd]
config_file_version = 2
domains = default
services = nss, pam
debug level = 0

[nss]
filter_users = root,ldap

[pam]

[domain/default]
cache_credentials = True

# For troubleshooting if you need to expire cache right away
entry_cache_timeout = 10

enumerate = False
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
access_provider = ldap

# LDAP configuration
ldap_sasl_mech = GSSAPI
ldap_sasl_authid = host/LDAP@ldapserver1.neustar.net,unixHS3profile@ldapserver1.neustar.net

ldap_schema = rfc2307bis
ldap_user_object_class = user
ldap_user_home_directory = unixHomeDirectory

ldap_user_fullname = displayName
ldap_user_search_base = dc=People,dc=neustar,dc=net
ldap_group_search_base = dc=Roles,dc=neustar,dc=net
ldap_group_member = member
ldap_group_nesting_level = 4

ldap_default_bind_dn = cn=fooServer,dc=Devices,dc=neustar,dc=net
ldap_default_authtok_type = password
ldap_default_authtok = yourSecretPassword
EOF

# Configure the client cert to be used by ldapsearch for user root.
sed -i '/^TLS_CERT.*\|^TLS_KEY.*/d' /root/ldaprc
cat >> /root/ldaprc  << EOF
TLS_CERT /etc/openldap/cacerts/client.pem
TLS_KEY /etc/openldap/cacerts/client.pem
EOF

#######################################################################################################################
# Configure sssd
#######################################################################################################################

# If the authentication provider is offline, specifies for how long to allow cached log-ins (in days). This value is 
# measured from the last successful online log-in. If not specified, defaults to 0 (no limit).

sed -i '/\[pam\]/a offline_credentials_expiration=5' /etc/sssd/sssd.conf

cat >> /etc/sssd/sssd.conf << EOF
# Enumeration means that the entire set of available users and groups on the
# remote source is cached on the local machine. When enumeration is disabled,
# users and groups are only cached as they are requested.
enumerate=true

# Configure client certificate auth.
ldap_tls_cert = /etc/openldap/cacerts/client.pem
ldap_tls_key = /etc/openldap/cacerts/client.pem
ldap_tls_reqcert = demand

# Only users with this employeeType are allowed to login to this computer.
access_provider = ldap
ldap_access_filter = (employeeType=neustar)

# Login to ldap with a specified user.
ldap_default_bind_dn = cn=sssd,dc=neustar,dc=net
ldap_default_authtok_type = password
ldap_default_authtok = secret
EOF


# Restart sssd
service sssd restart

# Start sssd after reboot.
chkconfig sssd on

#######################################################################################################################
# Configure the client to use sudo
#######################################################################################################################
sed -i '/^sudoers.*/d' /etc/nsswitch.conf
cat >> /etc/nsswitch.conf << EOF
sudoers: ldap files
EOF

sed -i '/^sudoers_base.*\|^binddn.*\|^bindpw.*\|^ssl on.*\|^tls_cert.*\|^tls_key.*\|sudoers_debug.*/d' /etc/ldap.conf
cat >> /etc/ldap.conf << EOF
# Configure sudo ldap.
uri ldaps://ldapserver1.neustar.net
base dc=neustar,dc=net
sudoers_base ou=SUDOers,dc=neustar,dc=net
binddn cn=sssd,dc=neustar,dc=net
bindpw secret
ssl on
tls_cacertdir /etc/openldap/cacerts
tls_cert /etc/openldap/cacerts/client.pem
tls_key /etc/openldap/cacerts/client.pem
#sudoers_debug 5
EOF    

# Here is an LDIF files that needs to be placed in the same folder as the above scripts.

# Filename: manager.ldif
#######################################################################################################################
# NEW DATABASE
######################################################################################################################
dn: dc=neustar,dc=net
objectClass: top
objectclass: dcObject
objectclass: organization
o: System Console Project
dc: neustar
description: Tree root

# Used by sssd to ask general queries.
dn: cn=sssd,dc=neustar,dc=net
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: sssd
description: Account for sssd.
userPassword: {SSHA}OjXYLr1oZ/LrHHTmjnPWYi1GjbgcYxSb

#######################################################################################################################
# Add pwdpolicy overlay
# Need to be done before adding new users.
#######################################################################################################################
dn: ou=pwpolicies,dc=neustar,dc=net
objectClass: organizationalUnit
objectClass: top
ou: policies

dn: cn=default,ou=pwpolicies,dc=neustar,dc=net
cn: default
#objectClass: pwdPolicyChecker

# The following are only commandline test values
# ldapsearch -x -ldapserver1.neustar.net -b '' -s base
# ldapsearch -x -h 192.168.1.23 -b '' -s base

