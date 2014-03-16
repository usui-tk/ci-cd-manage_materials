#! /bin/bash -v
LOGFILE=/tmp/cloud-init_script.log

echo cloud-init Execute START `date` >> ${LOGFILE}

echo cloud-init RHEL yum update Start `date` >> ${LOGFILE}
yum update -y rh-amazon-rhui-client >> ${LOGFILE}
yum-config-manager --enable rhui-REGION-rhel-server-supplementary  >> ${LOGFILE}
yum install -y yum-plugin-fastestmirror yum-plugin-changelog yum-plugin-priorities yum-plugin-versionlock yum-utils >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum install -y git >> ${LOGFILE}
yum update -y >> ${LOGFILE}
echo cloud-init RHEL yum update Complete `date` >> ${LOGFILE}

echo cloud-init Custom yum update Start `date` >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum localinstall -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum localinstall -y https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.amzn1.noarch.rpm >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum localinstall -y https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-11.10.4-1.el6.x86_64.rpm >> ${LOGFILE}
yum clean all >> ${LOGFILE}
yum update -y >> ${LOGFILE}
echo cloud-init Custom yum update Complete `date` >> ${LOGFILE}

echo cloud-init RHEL SSH Deamon Trouble Fix for RHEL v6.4-AMI Start `date` >> ${LOGFILE}
sed -i '/^cat/d' /etc/rc.d/rc.local
sed -i '/^UseDNS/d' /etc/rc.d/rc.local
sed -i '/^PermitRootLogin/d' /etc/rc.d/rc.local
sed -i '/^PermitRootLogin without-password/d' /etc/ssh/sshd_config
/usr/sbin/sshd -t >> ${LOGFILE}
/sbin/service sshd restart >> ${LOGFILE}
echo cloud-init RHEL SSH Deamon Trouble Fix for RHEL v6.4-AMI Complete `date` >> ${LOGFILE}

echo cloud-init RHEL TimeZone Setting Start `date` >> ${LOGFILE}
date >> ${LOGFILE}
/bin/cp -fp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
date >> ${LOGFILE}
/usr/sbin/ntpdate 0.rhel.pool.ntp.org >> ${LOGFILE}
date >> ${LOGFILE}
/sbin/chkconfig ntpd on >> ${LOGFILE}
/sbin/service ntpd start >> ${LOGFILE}
sleep 5
/usr/sbin/ntpq -p >> ${LOGFILE}
date >> ${LOGFILE}
echo cloud-init RHEL TimeZone Setting Complete `date` >> ${LOGFILE}

echo cloud-init RHEL Disabled IPv6 Function Start `date` >> ${LOGFILE}
echo "# Custom sysctl Parameter for ipv6 disable" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
/sbin/sysctl -p
/sbin/sysctl -a | grep -ie "local_port" -ie "ipv6" | sort >> ${LOGFILE}
echo "options ipv6 disable=1" >> /etc/modprobe.d/ipv6.conf
echo cloud-init RHEL Disabled IPv6 Function Complete `date` >> ${LOGFILE}


echo cloud-init RHEL Preset before the chef-solo command Start `date` >> ${LOGFILE}
mkdir -p /tmp/github >> ${LOGFILE}
git clone https://github.com/usui-tk/ci-cd-manage_materials.git /tmp/github >> ${LOGFILE}
chmod 777 /tmp/github/shellscript/ci_and_cd_manage-server.sh
#knife cookbook create ci-cd-manage -o /tmp/github/chef >> ${LOGFILE}
echo cloud-init RHEL Preset before the chef-solo command Complete `date` >> ${LOGFILE}


echo cloud-init RHEL 2nd-bootstrap Logic Settings Start `date` >> ${LOGFILE}
echo "/bin/sleep 30" >> /etc/rc.d/rc.local
#echo "/usr/bin/chef-solo -j /tmp/github/chef/ci-cd-manage/ci-cd-manage.json -c /tmp/github/chef/ci-cd-manage/solo.rb" >> /etc/rc.d/rc.local
echo "/bin/bash -ex /tmp/github/shellscript/ci_and_cd_manage-server.sh" >> /etc/rc.d/rc.local
echo "/bin/sed -i 's@/bin/sleep@#/bin/sleep@g' /etc/rc.d/rc.local" >> /etc/rc.d/rc.local
echo "/bin/sed -i 's@/usr/bin/chef-solo@#/usr/bin/chef-solo@g' /etc/rc.d/rc.local" >> /etc/rc.d/rc.local
echo "/bin/sed -i 's@/opt/aws/bin/cfn-signal@#/opt/aws/bin/cfn-signal@g' /etc/rc.d/rc.local" >> /etc/rc.d/rc.local
echo "/bin/sed -i 's@/bin/bash@#/bin/bash@g' /etc/rc.d/rc.local" >> /etc/rc.d/rc.local
echo "/bin/sed -i 's@/bin/sed@#/bin/sed@g' /etc/rc.d/rc.local" >> /etc/rc.d/rc.local
echo cloud-init RHEL 2nd-bootstrap Logic Settings Complete `date` >> ${LOGFILE}


echo cloud-init Root Disk Partition Resize Start `date` >> ${LOGFILE}
/sbin/fdisk -l >> ${LOGFILE}
/sbin/fdisk /dev/xvda << __EOF__ >> ${LOGFILE}
p
d
p
n
p
1
16

w
__EOF__
/sbin/fdisk -l >> ${LOGFILE}
echo cloud-init Root Disk Partition Resize Complete `date` >> ${LOGFILE}

echo cloud-init Swap File Create Start `date` >> ${LOGFILE}
sed -i 's@/dev/xvdb@#/dev/xvdb@g' /etc/fstab
/sbin/swapon -s >> ${LOGFILE}
/usr/bin/free >> ${LOGFILE}
/usr/bin/time dd if=/dev/zero of=/mnt/swap bs=1M count=1024 >> ${LOGFILE}
/sbin/mkswap /mnt/swap >> ${LOGFILE}
/sbin/swapon /mnt/swap >> ${LOGFILE}
/sbin/swapon -s >> ${LOGFILE}
/usr/bin/free >> ${LOGFILE}
cat /etc/fstab >> ${LOGFILE}
echo "/mnt/swap  swap      swap    defaults        0 0" >> /etc/fstab
cat /etc/fstab >> ${LOGFILE}
echo cloud-init Swap File Create Complete `date` >> ${LOGFILE}

echo cloud-init Execute Complete `date` >> ${LOGFILE}

/sbin/reboot >> ${LOGFILE}

