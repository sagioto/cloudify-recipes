#!/bin/bash

# args:
# $1 the error code of the last command (should be explicitly passed)
# $2 the message to print in case of an error
# 
# an error message is printed and the script exists with the provided error code
function error_exit {
	echo "$2 : error code: $1"
	exit ${1}
}

function killMySqlProcess {
	ps -ef | grep -iE "mysql" | grep -ivE "gigaspaces|GSC|GSA|grep"
	if [ $? -eq 0 ] ; then 
		ps -ef | grep -iE "mysql" | grep -ivE "gigaspaces|GSC|GSA|grep" | awk '{print $2}' | xargs sudo kill -9
	fi  
}

export PATH=$PATH:/usr/sbin:/sbin:/usr/bin || error_exit $? "Failed on: export PATH=$PATH:/usr/sbin:/sbin"

# The existence of the usingYum file in the ext folder will later serve as a flag that "we" are on Red Hat or CentOS or Fedora or Amazon
echo "Using yum. Updating yum on one of the following : Red Hat, CentOS, Fedora, Amazon. " > usingYum
sudo yum -y -q update || error_exit $? "Failed on: sudo yum -y -q update"

echo "#1 Killing old mysql process if exists..."
killMySqlProcess

echo "Removing previous mysql installation if exists..."
sudo yum -y -q remove mysql mysql-server

# The following two statements are used since in some cases, there are leftovers after uninstall
echo "Removing old stuff if exists..."
sudo rm -rf /usr/lib/mysql* || error_exit $? "Failed on: sudo rm -rf /usr/lib/mysql*"
sudo rm -rf /var/lib/mysql* || error_exit $? "Failed on: sudo rm -rf /var/lib/mysql*"
sudo rm -rf /usr/share/mysql* || error_exit $? "Failed on: sudo rm -rf /usr/sharemysql*"
sudo rm -rf /usr/bin/mysql* || error_exit $? "Failed on: sudo rm -rf /usr/bin/mysql*"
sudo rm -rf /var/run/mysql* || error_exit $? "Failed on: sudo rm -rf /var/run/mysql*"
sudo rm -rf /var/bin/mysql* || error_exit $? "Failed on: sudo rm -rf /var/bin/mysql*"
sudo rm -rf /etc/mysql* || error_exit $? "Failed on: sudo rm -rf /etc/mysql*"
sudo rm -rf /etc/rc.d/init.d/mysql* || error_exit $? "Failed on: sudo rm -rf /etc/rc.d/init.d/mysql*"
sudo rm -rf /usr/libexec/mysql* || error_exit $? "Failed on: sudo rm -rf /usr/libexec/mysqld*" 
sudo rm -rf /etc/my.cnf || error_exit $? "Failed on: sudo rm -rf /etc/my.cnf" 
sudo rm -rf /var/log/mysql* || error_exit $? "Failed on: sudo rm -rf /var/log/mysql*" 
#sudo rm -f /home/`whoami`/{.,}*mysql* || error_exit $? "Failed on: sudo rm -f /home/`whoami`/{.,}*mysql*" 

echo "Using yum. Installing mysql on one of the following : Red Hat, CentOS, Fedora, Amazon"
sudo yum install -y -q mysql mysql-server || error_exit $? "Failed on: sudo yum install -y -q mysql mysql-server "
echo "Reinstalling mysql-libs ..."
sudo yum reinstall -y -q mysql-libs || error_exit $? "Failed on: sudo yum install -y -q mysql mysql-server "

echo "Killing old mysql process if exists b4 ending the installation..."
killMySqlProcess


myCnfPath=`sudo find / -name "my.cnf"`
if [ -f "${myCnfPath}" ] ; then
    allZeroes="0.0.0.0"
	bindcount=`grep -c "bind-address" $myCnfPath`
    if [ $bindcount -eq 0 ] ; then
	  bindStr="bind-address=${allZeroes}"
	  mysqldStr="\[mysqld\]"
	  jointStr="${mysqldStr}\n${bindStr}"
	  echo "Adding ${bindStr} $myCnfPath ... "
      sudo sed -i -e "s/$mysqldStr/$jointStr/g" $myCnfPath
	else
		orig127="127.0.0.1"
		echo "Replacing $orig127 with $allZeroes in $myCnfPath ... "
		sudo sed -i -e "s/$orig127/$allZeroes/g" $myCnfPath
	fi
fi

echo "End of $0"


