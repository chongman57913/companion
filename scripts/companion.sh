#!/bin/bash

#Make sure script is not run as root user
if [ "$UID" = "0" ];then
	echo "Don't run the script with root preivilages."
	exit -1
fi

#Print usage/help page
if [ "$1" != "update" ] && [ "$1" != "install" ];then
	clear

	bold=$(tput bold)
	normal=$(tput sgr0)

	echo "${bold}NAME${normal}"
	echo -e "\tcompanion.sh - Package to setup Nvidia Jetson TX1/TX2 as companion \n\tboard for Pixhawk."
	echo ""
	echo "${bold}USAGE${normal}"
	echo -e "\tUnless the -h, or --help option is given, one of the commands below\n\tmust be present."
	echo ""
	echo "${bold}install${normal}"
	echo -e "\tUsed only once when setting up the board for the first time."
	echo ""
	echo "${bold}update${normal}"
	echo -e "\tUsed to update all packages needed to run the jetson as a companion\n\tboard. It also updates the packages built from source if any changes\n\twere made to the remote repo"
	echo ""

	exit 0
fi

#Function to update file if changes are not there
update_file(){
	grep "$1" $2
	if [ $? != 0 ];then
		echo "$1" >> $2
	fi
}

#Function to update file as root user if changes are not there
sudo_update_file(){
	grep "$1" $2
	if [ $? != 0 ];then
		sudo sh -c "echo '$1' >> $2"
	fi
}

#Function to clone repo if it doesnt exist and update repo if it exists
get_repo(){
	if [ -d $1 ];then
		cd $1
		git reset --hard origin/master
		git fetch origin master
		flag=$(git status | grep "behind" | wc -l)
		cd $HOME
		if [ $flag -gt 0 ];then
			return -2
		else
			return 0
		fi
	else
		git clone $2 $1
		if [ $? != 0 ];then
			echo "Can't clone $1 repo"
			exit -1
		fi
		return -1
	fi
}

#create logs folder if not there
if [ ! -d $HOME/companion/logs ];then
	mkdir $HOME/companion/logs
fi

#run only if update flag was not set
if [ "$1" != "update" ]; then
	#Remove liberoffice
	sudo apt-get purge libreoffice-* -y
fi

#update and upgrade
sudo apt-get update
sudo apt-get upgrade -y

#run only if update flag was not set
if [ "$1" != "update" ]; then
	# run system config
	bash $HOME/companion/scripts/run_system_config.sh	
	
	#add universe repo
	sudo apt-get install software-properties-common -y
	sudo apt-add-repository universe -y
	sudo apt-get update

	#install required packages
	sudo apt-get install -y git screen openssh-server nano
	sudo apt-get install -y gstreamer1.0-plugins-base python-gst-1.0 gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gir1.2-gst-plugins-base-1.0 gir1.2-gstreamer-1.0
	sudo apt-get install -y python-dev python-opencv python-pip python-libxml2  python-wxgtk3.0 python-matplotlib python-pygame
	sudo apt-get install -y python-setuptools python-dev build-essential
	sudo apt-get install -y libxml2-dev libxslt1-dev

	sudo -H pip install pip -U
	sudo -H pip install future
	sudo -H pip install pyserial -U


	# Python 3
	sudo apt-get install -y python3-pip
	sudo pip3 install -U pip testresources setuptools future==0.17.1 pyserial pymavlink 

	#remove modemmanager interferes with serial devices and add user to dialout to get access to serial devices
	sudo apt-get purge modemmanager -y
	sudo adduser $USER dialout

	#update environment variables
	update_file "export PATH=$PATH:$HOME/.local/bin:$HOME/companion/scripts:$HOME/companion/tools" ~/.bashrc
	source ~/.bashrc
fi

# Install mavlink & pymavlink
cd $HOME
git clone https://github.com/mavlink/mavlink.git $HOME/mavlink

pushd mavlink
git submodule init && git submodule update --recursive
pushd pymavlink
sudo python setup.py build install
popd
popd

# Install MAVProxy
cd $HOME
git clone https://github.com/bluerobotics/MAVProxy.git $HOME/mavproxy
pushd mavproxy
git pull origin master
sudo python setup.py build install
popd

#run only if update flag was not set
if [ "$1" != "update" ]; then
	#update rc.local to start scripts on boot
	S1="sleep 2"
	S2="sudo -H -u $USER /bin/bash -c '$HOME/companion/scripts/autostart_mavproxy.sh'"
	S3="sudo -H -u $USER /bin/bash -c '$HOME/companion/scripts/autostart_gstreamer.sh'"

	sudo sh -c "echo '#!/bin/bash' >> /etc/rc.local"
	sudo sh -c "echo $S1 >> /etc/rc.local"
	sudo sh -c "echo $S2 >> /etc/rc.local"
	sudo sh -c "echo $S3 >> /etc/rc.local"

	sudo chmod u+x /etc/rc.local

	#create symbolic link for pixhawk in /dev
	sudo sh -c "echo 'SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"26ac\", ATTRS{idProduct}==\"0011\", SYMLINK+=\"pixhawk\"' > /etc/udev/rules.d/99-usb-serial.rules"
	sudo udevadm trigger

	#setup static ip address 192.168.2.2
	sudo sh -c "echo '\n' >> /etc/network/interfaces"
	sudo_update_file "## ROV direct connection" /etc/network/interfaces
	sudo_update_file "auto eth0" /etc/network/interfaces
	sudo_update_file "iface eth0 inet static" /etc/network/interfaces
	sudo_update_file "    address 192.168.2.2" /etc/network/interfaces
	sudo_update_file "    netmask 255.255.255.0" /etc/network/interfaces

	#install ros
	#$HOME/companion/scripts/install_ros.sh

	# install deep learning framework
	bash $HOME/companion/scripts/install_deep_learning_framework.sh

	# install remote desktop
	bash $HOME/companion/scripts/install_xrdp.sh
fi

sudo apt-get autoremove -y
sudo apt-get autoclean -y

#Disable gui
#sudo systemctl disable lightdm.service
#sudo chmod -x /usr/sbin/lightdm

#Restart Jetson
sudo shutdown -r now
