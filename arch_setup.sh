ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_TW.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "CubecSilicon" > /etc/hostname
passwd
useradd -mG wheel cubeman
echo "%wheel ALL=(ALL:ALL)  ALL" > /etc/sudoers.d/settings
grub() {

	yes | sudo pacman -S grub os-prober eifbootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub --removable
	mkdir /etc/default/grub.d
	echo "GRUB_DISABLE_OS_PROBER=false" > /etc/default/grub.d/os-prob.cfg
	grub-mkconfig -o /boot/grub.cfg
}
ssh(){
	yes | sudo pacman -S openssh
	mkdir /etc/ssh/sshd_config.d
	echo "Port 16384" >> /etc/ssh/sshd_config.d/settings.conf
	echo "HostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config.d/settings.conf
	echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config.d/settings.conf
	systemctl enable sshd.service
}

nvidia-driver(){
	yes | sudo pacman -S nvidia
	echo "options nouveau modeset=0" >> /etc/modprobe.d/nvidia.conf
	echo "options nvidia_drm modeset=1 fbdev=1" >> etc/modeprobe.d/nvidia.conf
}
Desktop_env(){
	pacman -S plasma
	yes | sudo pacman -S sddm konsole dolphin firefox gwenview vlc gedit noto-fonts-cjk
	echo "[Theme]" >> /etc/sddm.conf.d/theme.conf
	echo "DisplayServer=wayland" >> /etc/sddm.conf.d/theme.conf
	echo "Current=breeze" >> /etc/sddm.conf.d/theme.conf
	systemctl enable sddm
	yes | sudo pacman -S fcitx5 fcitx5-chewing fcitx5-breeze fcitx5-configtool
}


