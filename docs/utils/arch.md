# Installare archlinux

## Set della tastiera in ita

loadkeys it

## Connessione alla WIFI

entrare nel tool
iwctl

lista delle interfacce di rete
[iwd]# device list

trovare le reti per quell'interfaccia
[iwd]# station wlan0 get-networks


[iwd]# station wlan0 connect <nome rete> 
e inserire la password

[iwd]# exit

## archinstall

### Archinstall language
la lingua dell'installer

### Locales
- dove scegliere la lingua della tastiera (keyboard layout)
- la lingua del sistema
- l'encoding

### mirrors
scegliere il mirror più vicino per il download dei pacchetti

### disk configuration
per scegliere il partizionamento

c'è l'opzione automatica "best effort", scegliere il disco e il formato del disco

### disk encriptyion


### swap

### bootloader
systemd-boot

### unified kernel image

### hostname
il nome della macchina

### root password

### user account
per creare un account iniziale oltre a root

### profile
scegliere il tipo di installazione -> desktop
scegliere il window manager
scegliere i driver grafici
scegliere il greeter (sddm di default)

### audio

scegliere i driver audio (pipewire)

### kernels
scegliere i kernel da installare, per sicurezza installare anche linux-lts

### network configuration
networkmanager


## post install

### fix /dev/tpmrm0
https://bbs.archlinux.org/viewtopic.php?id=296699

systemctl mask dev-tpmrm0.device

### pacchetti base
sudo pacman -Sy zsh firefox


### yay
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

### oh-my-zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
