#!/bin/bash
user_name=""
encrypted_user_passwd=''
encrypted_root_passwd=''

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$(basename "${BASH_SOURCE[0]}")"

next_line(){
	echo "while [ true ]; do" > /root/next_line.sh
	echo 'printf "\\n"' >> /root/next_line.sh
	echo "done" >> /root/next_line.sh
	chmod +x /root/next_line.sh
}
basic_config(){
	# setting mirror
	sed -e 10a\ 'Server = https://archlinux.cs.nycu.edu.tw/$repo/os/$arch' /etc/pacman.d/mirrorlist > /tmp/mirrorlist
	cat /tmp/mirrorlist > /etc/pacman.d/mirrorlist
	rm /tmp/mirrorlist
	# timeZone
	ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
	hwclock --systohc
	# locale
	cat /etc/locale.gen | sed -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' > /tmp/locale.gen
	cat /tmp/locale.gen > /etc/locale.gen
	rm /tmp/locale.gen

	cat /etc/locale.gen | sed -e 's/^#zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/' > /tmp/locale.gen
	cat /tmp/locale.gen > /etc/locale.gen
	rm /tmp/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	# hostname
	echo "sa2024-" > /etc/hostname
	# sudo	
	echo "%wheel ALL=(ALL:ALL)  ALL" > /etc/sudoers.d/settings
	# enable NetworkManager
	systemctl enable NetworkManager.service
	# root passwd
	echo "root:$encrypted_root_passwd" | chpasswd -e
	# add user
	useradd -mNG wheel "$user_name"
	echo "$user_name:$encrypted_user_passwd" | chpasswd -e
	# add judge user
	useradd -mNG wheel -s /bin/sh judge
	groupadd nycusa -U judge
	echo "%nycusa ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/settings
	# motd
	echo 'NYCU-SA-2024-' >> /etc/motd
	# WireGuard
	yes | pacman -S wireguard-tools
	echo '[Interface]' >> /etc/wireguard/wg0.conf
	echo 'PrivateKey = ' >> /etc/wireguard/wg0.conf 
	echo 'Address = ' >> /etc/wireguard/wg0.conf
	echo '[Peer]' >> /etc/wireguard/wg0.conf
	echo 'PublicKey = ' >> /etc/wireguard/wg0.conf
	echo 'AllowedIPs = ' >> /etc/wireguard/wg0.conf
	echo 'Endpoint = ' >> /etc/wireguard/wg0.conf
	echo 'PersistentKeepalive = ' >> /etc/wireguard/wg0.conf
}
grub(){
	yes | pacman -S grub os-prober efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub --removable
	mkdir /etc/default/grub.d
	echo "GRUB_DISABLE_OS_PROBER=false" > /etc/default/grub.d/os-prob.cfg
	grub-mkconfig -o /boot/grub/grub.cfg
}
ssh_config(){
	yes | pacman -S openssh
	echo "HostKey /etc/ssh/ssh_host_rsa_key" > /etc/ssh/sshd_config.d/settings.conf
	echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config.d/settings.conf
	systemctl enable sshd.service
	mkdir /home/judge/.ssh
	curl 'https://nasa.cs.nycu.edu.tw/sa/2024/nasakey.pub' >> /home/judge/.ssh/authorized_keys
}
nvidia_driver(){
	if [ -z "$(lspci | grep 'VGA' | grep 'NVIDIA')" ]; then
		echo "no NVIDIA GPU detected"
	else
		yes | pacman -S nvidia nvidia-utils nvidia-settings opencl-nvidia
		echo "options nouveau modeset=0" > /etc/modprobe.d/nvidia.conf
		echo "options nvidia_drm modeset=1 fbdev=1" >> /etc/modprobe.d/nvidia.conf
	fi
}
Desktop_env(){
	next_line
	/root/next_line.sh | pacman -S plasma sddm noto-fonts-cjk
	yes | pacman -S konsole dolphin firefox gwenview vlc gedit
	mkdir /etc/sddm.conf.d/
	echo "[Theme]" > /etc/sddm.conf.d/theme.conf
	echo "DisplayServer=wayland" >> /etc/sddm.conf.d/theme.conf
	echo "Current=breeze" >> /etc/sddm.conf.d/theme.conf
	/root/next_line.sh | pacman -S fcitx5 fcitx5-chewing fcitx5-breeze fcitx5-configtool
 	
 	systemctl enable sddm
}
vscode(){
	wget -P /tmp/ `curl 'https://code.visualstudio.com/sha/download?build=stable&os=linux-x64' | sed 's/http/\nhttp/g' | grep http`
	tar -zxf /tmp/code-stable*.tar.gz -C /usr/lib
	ln -s /usr/lib/VSCode-linux-x64/code /usr/bin/code
}
others(){
	yes | pacman -S sl cmatrix cowsay figlet neofetch tmux
}
STATE="$1"

if [ -z "$STATE" ]; then
	STATE="base"
fi

case "$STATE" in
	base)
 		timedatectl
		pacstrap -K /mnt base linux linux-firmware base-devel networkmanager vim man-db net-tools git wget
		genfstab -U /mnt >> /mnt/etc/fstab

		cp -p "${BASH_SOURCE[0]}" "/mnt/root"
		arch-chroot /mnt "/root/$SCRIPT_FILE" "chroot"
		
		rm "/mnt/root/$SCRIPT_FILE"
		exit 0
		;;
	chroot)
		next_line
		basic_config
		grub
		ssh_config
		nvidia_driver
		install_yay
		Desktop_env
		vscode
		others
		rm /root/next_line.sh
		exit 0
		;;
esac
