
#!/usr/bin/env bash

echo "Welcome To BiffJonas Arch installation"

echo "Please enter the Main Hardrive (sda, sdb, sdc)"
read MAIN

echo "Please enter BOOT(/boot) paritition: (The tiny one)"
read BOOT

echo "Please enter EFI(/boot/efi) paritition: (The really tiny one)"
read EFI

echo "Please enter Root(/) paritition: (Should be about 4G)"
read ROOT 

echo "Please enter home(/home) paritition: (The big one...)"
read HOME

echo "Please enter your username"
read USER 

echo "Please enter your password"
read PASSWORD 

echo "Please choose Your Bloat"
echo "1. GNOME"
echo "2. KDE"
echo "3. XFCE"
echo "4. NoDesktop"
read DESKTOP

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.ext4 "${ROOT}"
mkfs.ext4 "${HOME}"
mkfs.ext4 "${BOOT}"
mkfs.fat -F 32 "${EFI}"


# mount partitions
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount "${ROOT}" /mnt
mount "${BOOT}" /mnt/boot
mount "${EFI}" /mnt/boot/efi
mount "${HOME}" /mnt/home

echo "--------------------------------------"
echo "-- INSTALLING Arch Linux BASE on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel vim git --noconfirm --needed

# kernel
pacstrap /mnt linux linux-firmware --noconfirm --needed

echo "--------------------------------------"
echo "-- Setup Dependencies               --"
echo "--------------------------------------"

pacstrap /mnt networkmanager grub efibootmgr --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "--------------------------------------"
echo "-- Bootloader Installation  --"
echo "--------------------------------------"

grub-install "${MAIN}"
grub-mkconfig -o /mnt/boot/grub/grub.cfg

cat <<REALEND > /mnt/next.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
hwclock --systohc

echo "BiffArch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	arch.localdomain	arch
EOF

echo "-------------------------------------------------"
echo "Display and Audio Drivers"
echo "-------------------------------------------------"

pacman -S xorg pulseaudio --noconfirm --needed

systemctl enable NetworkManager

#DESKTOP ENVIRONMENT
if [[ $DESKTOP == '1' ]]
then 
    pacman -S gnome gdm --noconfirm --needed
    systemctl enable gdm
elif [[ $DESKTOP == '2' ]]
then
    pacman -S plasma sddm kde-applications --noconfirm --needed
    systemctl enable sddm
elif [[ $DESKTOP == '3' ]]
then
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed
    systemctl enable lightdm
else
    echo "You have choosen no bloat \"Happy Ending\""
fi

echo "-------------------------------------------------"
echo "Install Complete, You can reboot now"
echo "-------------------------------------------------"

REALEND


arch-chroot /mnt sh next.sh
