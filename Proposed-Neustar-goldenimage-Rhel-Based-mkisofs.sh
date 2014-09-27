!#/bin/bash -v
mount /dev/cdrom /mnt/ -o loop # mount /dev/sr0 /mnt -o loop
mkdir /Neustargoldenimage
shopt -s dotglob
cp -ri /mnt/* /Neustargoldenimage

cat >> /Neustar-goldenimage/ks.cfg << EOF
install
cdrom
#repo --name="Red Hat Enterprise Linux"  --baseurl=file:/mnt/source --cost=100
#repo --name="High Availability"  --baseurl=file:/mnt/source/HighAvailability --cost=1000
lang en_US.UTF-8
keyboard us
timezone --utc America/New_York
selinux --enforcing
authconfig --enableshadow --passalgo=sha512
xconfig --startxonboot #--resolution=800x600
firstboot --disable
firewall --service=ssh
bootloader --location=mbr --password=afunde21 --driveorder=sda,sdb,sdc --append="rhgb quiet"
zerombr 
clearpart --all --initlabel
part /boot --fstype "ext4" --size=512 --asprimary
part swap --fstype swap --size=3024
part pv.01 --size=1 --grow
part pv.02 --size=1 --grow
part pv.03 --size=1 --grow


volgroup vgroup1 pv.02
logvol /     --fstype ext4 --name=root --vgname=vgroup1 --size=25600 --grow
logvol /tmp  --fstype ext4 --name=tmp --vgname=vgroup1 --size=5000 --fsoptions="nodev,noexec,nosuid"
logvol /home --fstype ext4 --name=home --vgname=vgroup1 --size=1024 --fsoptions="nodev"
volgroup vgroup2 pv.03
logvol /var  --fstype ext4 --name=var  --vgname=vgroup2 --size=1024 --fsoptions="nodev"
logvol /var/log --fstype ext4 --name=varlog --vgname=vgroup2 --size=512 --fsoptions="nodev,noexec,nosuid"
logvol /var/log/audit --fstype ext4 --name=audit --vgname=vgroup2 --size=256 --fsoptions="nodev,noexec,nosuid"

%packages --ignoremissing
@base
@base-x
@core
@editors
@gnome-desktop
@graphical-internet
@graphics
@java
@perl-runtime
@legacy-software-support
@Internet Browser
@X Window System
mtools
gdm
gcc
patch
binutils
krb5-pkinit-openssl
krb5-server
krb5-server-ldap
krb5-workstation
lftp
oddjob
openldap-clients
openldap-servers
openscap
openscap-utils
pam_krb5
pam_ldap
perl-CGI
perl-DBD-SQLite
perl-Date-Manip
perl-Frontier-RPC
policycoreutils-gui
python-dmidecode
python-memcached
samba
samba-winbind
setroubleshoot
system-config-kickstart
system-config-lvm
tcp_wrappers
vim-X11
yum-plugin-aliases
yum-plugin-changelog
yum-plugin-downloadonly
yum-plugin-tmprepo
yum-plugin-verify
yum-plugin-versionlock
yum-plugin-fastestmirror.noarch
yum-rhn-plugin.noarch
yum-utils.noarch
yum-plugin-security.noarch
yum-presto
yum-metadata-parser.x86_64

%post
cp /boot/grub/menu.lst /boot/grub/grub.conf.bak
sed -i 's/ rhgb//' /boot/grub/grub.conf
if [ -f /etc/rc.d/rc.local ]; then cp /etc/rc.d/rc.local /etc/rc.d/rc.local.backup; fi
cat >>/etc/rc.d/rc.local <<EOF

sed -i "/pam_cracklib.so/s/retry=3/retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1 difok=3/" /etc/pam.d/system-auth
sed -i "5i\auth\trequired\tpam_tally2.so deny=5 onerr=fail" /etc/pam.d/system-auth
sed -i "/PROMPT/s/yes/no/" /etc/sysconfig/init

gconftool-2 --direct \
              --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
              --type int \
              --set /apps/gnome-screensaver/idle_delay 15

gconftool-2 --direct \
              --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
              --type bool \
              --set /apps/gnome-screensaver/idle_activation_enabled true

gconftool-2 --direct \
              --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
              --type bool \
              --set /apps/gnome-screensaver/lock_enabled true

gconftool-2 --direct \
              --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
              --type string \
              --set /apps/gnome-screensaver/mode blank-only

echo -e "\n-- WARNING --\nThis system is for the use of authorized users only. Individuals\nusing this computer system without authority or in excess of their\nauthority are subject to having all their activities on this system\nmonitored and recorded by system personnel. Anyone using this\nsystem expressly consents to such monitoring and is advised that\nif such monitoring reveals possible evidence of criminal activity\nsystem personal may provide the evidence of such monitoring to law\nenforcement officials.\n" > /etc/issue

sed -i "15s/<item type=\"rect\">/<item type=\"rect\" id=\"custom-usgcb-banner\">\n        <posv anchor=\"nw\" x=\"20%\" y=\"10\" width=\"80%\" height=\"100%\"\/>\n        <box>\n            <item type=\"label\">\n            <normal font=\"Sans Bold 9\" color=\"#ffffff\"\/>\n            <text>\n-- WARNING --\nThis system is for the use of authorized users only. Individuals\nusing this computer system without authority or in excess of their\nauthority are subject to having all their activities on this system\nmonitored and recorded by system personnel. Anyone using this\nsystem expressly consents to such monitoring and is advised that\nif such monitoring reveals possible evidence of criminal activity\nsystem personnel may provide the evidence of such monitoring to law\nenforcement officials.\n            <\/text>\n            <\/item>\n        <\/box>\n    <\/item>\n\n    <item type=\"rect\">/" /usr/share/gdm/themes/RHEL/RHEL.xml

chkconfig mcstrans off

echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.secure_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.secure_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
echo "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter = 1" >> /etc/sysctl.conf
echo -e "options ipv6 disable=1" >> /etc/modprobe.d/usgcb-blacklist
echo "net.ipv6.conf.default.accept_redirect=0" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.accept_ra=0" >> /etc/sysctl.conf
EOF

chkconfig ip6tables off && service ip6tables stop
chkconfig iptables on && service iptables save && service iptables restart
sysctl -p      #Enables the above modifications of sysctl.conf


cat > /Neustargoldenimage/isolinux/isolinux.cfg <<
default vesamenu.c32
#prompt 1
timeout 600

display boot.msg

menu background splash.jpg
menu title Welcome to CentOS 6.5!
menu color border 0 #ffffffff #00000000
menu color sel 7 #ffffffff #ff000000
menu color title 0 #ffffffff #00000000
menu color tabmsg 0 #ffffffff #00000000
menu color unsel 0 #ffffffff #00000000
menu color hotsel 0 #ff000000 #ffffffff
menu color hotkey 7 #ffffffff #ff000000
menu color scrollbar 0 #ffffffff #00000000

label linux
  menu label ^Install or upgrade an existing system
  menu default
  kernel vmlinuz
  append initrd=initrd.img ks=cdrom:/ks.cfg
label vesa
  menu label Install system with ^basic video driver
  kernel vmlinuz
  append initrd=initrd.img xdriver=vesa nomodeset
label rescue
  menu label ^Rescue installed system
  kernel vmlinuz
  append initrd=initrd.img rescue
label local
  menu label Boot from ^local drive
  localboot 0xffff
label memtest86
  menu label ^Memory test
  kernel memtest
  append -
EOF

cd /goldenimage
mkisofs -o /root/Desktop/rhel7.iso -b isolinux/isolinux.bin -c isolinux/boot.cat --no-emul-boot --boot-load-size 4 --boot-info-table -J -R -V disks .

# Epel and Remi repositories
# Rhel-Based 7 Oses
# rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-1.noarch.rpm 
# rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

# Rhel-based 6 oses
# rpm -Uvh http://dl.fedoraproject.org/pub/epel/6Server/x86_64/epel-release-6-8.noarch.rpm 
# rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# Rhel-based 5 Oses
# rpm -Uvh http://dl.fedoraproject.org/pub/epel/5Server/x86_64/epel-release-5-4.noarch.rpm
# rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-5.rpm

# WEBMIN REPO
# yum -y install http://sourceforge.net/projects/webadmin/files/webmin/1.680/webmin-1.680-1.noarch.rpm
# chkconfig webmin on && /etc/init.d/webmin start

# Mondo Rescue backup solutions
# Rhel-based 6
# rpm -Uvh ftp://ftp.mondorescue.org/rhel/6/x86_64/mondo-2.2.9.6-1.rhel6.x86_64.rpm

