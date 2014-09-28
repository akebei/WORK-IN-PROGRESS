#!/bin/bash
YUM=/usr/bin/yum                                   # Line updates yum itself
$YUM -y -R 120 -d 0 -e 0 update yum                # -R 120: maxi amount of time yum can wait to perform a cmd
$YUM -y -R 10 -e 0 -d 0 update                      # -e 0: error level set to 0, -d 0 sets debugging level to 0

# chmod u+x /etc/cron.daily/yumdate.sh

# if [ -f /var/lock/subsys/yum ]; then
#        /usr/bin/yum -R 10 -e 0 -d 1 -y update yum
#        /usr/bin/yum -R 120 -e 0 -d 1 -y update
# fi
# chkconfig yum on
# /etc/init.d/yum start
