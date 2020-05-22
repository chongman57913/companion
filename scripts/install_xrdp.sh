sudo apt-get install -y xrdp

# issue caused by gnome
# use xface4 for xrdp
# https://forums.developer.nvidia.com/t/issue-with-xrdp/110654

sudo apt install -y xfce4

# start xrdp with xfce4
sudo mv /etc/xrdp/startwm.sh /etc/xrdp/startwm_tmp.sh
sudo sh -c "sudo head -n -2 /etc/xrdp/startwm_tmp.sh > /etc/xrdp/startwm.sh"
sudo sh -c "echo startxfce4 >> /etc/xrdp/startwm.sh"
sudo chmod 655 /etc/xrdp/startwm.sh