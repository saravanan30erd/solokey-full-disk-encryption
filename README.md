# SoloKey Full Disk Encryption

This project leverages a [SoloKey](https://wiki.archlinux.org/index.php/Solo) [HMAC Challenge-Response](https://github.com/solokeys/solo-python#challenge-response) mode for creating strong [LUKS](https://gitlab.com/cryptsetup/cryptsetup) encrypted volume passphrases. It can be used in intramfs stage during boot process as well as on running system.

SoloKey uses two inputs, challenge and credential to generate the response. The response will be used as your LUKS encrypted volume passphrase.

This was only tested and intended for:

* [Arch Linux](https://www.archlinux.org/) and its derivatives

Table of Contents
=================

   * [SoloKey Full Disk Encryption](#solokey-full-disk-encryption)
   * [Table of Contents](#table-of-contents)
   * [Prerequisites](#prerequisites)
   * [Install](#install)
      * [From Github using 'make'](#from-github-using-make)
   * [Configure](#configure)
      * [Configure HMAC-SHA1 Challenge-Response slot in SoloKey](#configure-hmac-sha1-challenge-response-slot-in-SoloKey)
      * [Edit /etc/skfde.conf file](#edit-etcskfdeconf-file)
   * [Usage](#usage)
      * [Format new LUKS encrypted volume using skfde passphrase](#format-new-luks-encrypted-volume-using-skfde-passphrase)
      * [Enroll skfde passphrase to existing LUKS encrypted volume](#enroll-skfde-passphrase-to-existing-luks-encrypted-volume)
      * [Enroll new skfde passphrase to existing LUKS encrypted volume protected by old skfde passphrase](#enroll-new-skfde-passphrase-to-existing-luks-encrypted-volume-protected-by-old-skfde-passphrase)
      * [Unlock LUKS encrypted volume protected by skfde passphrase](#unlock-luks-encrypted-volume-protected-by-skfde-passphrase)
      * [Kill skfde passphrase for existing LUKS encrypted volume](#kill-skfde-passphrase-for-existing-luks-encrypted-volume)
      * [Enable skfde initramfs hook](#enable-skfde-initramfs-hook)
      * [Enable NFC support in skfde initramfs hook (experimental)](#enable-nfc-support-in-skfde-initramfs-hook-experimental)
      * [Enable skfde suspend service (experimental)](#enable-skfde-suspend-service-experimental)
   * [License](#license)

# Prerequisites

## Install the dependency tool [fido2luks](https://github.com/shimunn/fido2luks)

```
pacman -S clang cargo git
git clone https://github.com/shimunn/fido2luks
cd fido2luks
cargo install -f --path . --root /usr
```

If you get the error in rust `error: no default toolchain configured`, please run the below command.

```
rustup install stable
rustup default stable
```

# Install

## From Github using 'make'

```
git clone https://github.com/saravanan30erd/solokey-full-disk-encryption
cd solokey-full-disk-encryption
sudo make install
```

# Configure

## Configure HMAC-SHA1 Challenge-Response slot in SoloKey

First of all you need to [setup a configuration slot](https://wiki.archlinux.org/index.php/SoloKey#Setup_the_slot) for *SoloKey HMAC-SHA1 Challenge-Response* mode using a command similar to:

```
ykpersonalize -v -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible -ochal-btn-trig
```

Above arguments mean:

* Verbose output (`-v`)
* Use slot 2 (`-2`)
* Set Challenge-Response mode (`-ochal-resp`)
* Generate HMAC-SHA1 challenge responses (`-ochal-hmac`)
* Calculate HMAC on less than 64 bytes input (`-ohmac-lt64`)
* Allow SoloKey serial number to be read using an API call (`-oserial-api-visible`)
* Require touching SoloKey before issue response (`-ochal-btn-trig`) *(optional)*

This command will enable *HMAC-SHA1 Challenge-Response* mode on a chosen slot and write random 20 byte length secret key to your SoloKey which will be used for creating skfde passphrases.

**Warning: choosing SoloKey slot already configured for *HMAC-SHA1 Challenge-Response* mode will overwrite secret key with the new one which means skfde passphrases created with the old key will be unrecoverable.**

You may instead enable *HMAC-SHA1 Challenge-Response* mode using graphical interface through [SoloKey-personalization-gui](https://www.archlinux.org/packages/community/x86_64/SoloKey-personalization-gui/) package. It allows for customization of the secret key, creation of secret key backup and writing the same secret key to multpile SoloKeys which allows for using them interchangeably for creating same skfde passphrases.

## Edit /etc/skfde.conf file

Open the [/etc/skfde.conf](https://github.com/agherzan/SoloKey-full-disk-encryption/blob/master/src/skfde.conf) file and adjust it for your needs. Alternatively to setting `skfde_DISK_UUID` and `skfde_LUKS_NAME`, you can use `cryptdevice` kernel parameter. The [syntax](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Configuring_the_kernel_parameters) is compatible with Arch's `encrypt` hook. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```
sudo mkinitcpio -P
```


# Usage
You can list existing LUKS key slots with `cryptsetup luksDump /dev/<device>`.

## Format new LUKS encrypted volume using skfde passphrase

To format new *LUKS* encrypted volume, you can use [skfde-format](https://github.com/agherzan/SoloKey-full-disk-encryption/blob/master/src/skfde-format) script which is wrapper over `cryptsetup luksFormat` command:

```
skfde-format --cipher aes-xts-plain64 --key-size 512 --hash sha512 /dev/<device>
```

## Enroll skfde passphrase to existing LUKS encrypted volume

To enroll new skfde passphrase to existing *LUKS* encrypted volume you can use [skfde-enroll](https://github.com/agherzan/SoloKey-full-disk-encryption/blob/master/src/skfde-enroll) script, see `skfde-enroll -h` for help:

```
skfde-enroll -d /dev/<device> -s <keyslot_number>
```

**Warning: having a weaker non-skfde passphrase(s) on the same *LUKS* encrypted volume undermines the skfde passphrase value as potential attacker will always try to break the weaker passphrase. Make sure the other  non-skfde passphrases are similarly strong or remove them.**

## Enroll new skfde passphrase to existing LUKS encrypted volume protected by old skfde passphrase

To enroll new skfde passphrase to existing *LUKS* encrypted volume protected by old skfde passphrase you can use [skfde-enroll](https://github.com/agherzan/SoloKey-full-disk-encryption/blob/master/src/skfde-enroll) script, see `skfde-enroll -h` for help:

```
skfde-enroll -d /dev/<device> -s <keyslot_number> -o
```

## Unlock LUKS encrypted volume protected by skfde passphrase

To unlock *LUKS* encrypted volume on a running system, you can use [skfde-open](https://github.com/agherzan/SoloKey-full-disk-encryption/blob/master/src/skfde-open) script, see `skfde-open -h` for help.

As unprivileged user using udisksctl (recommended):

```
skfde-open -d /dev/<device>
```

As root using cryptsetup (when [udisks2](https://www.archlinux.org/packages/extra/x86_64/udisks2/) or [expect](https://www.archlinux.org/packages/extra/x86_64/expect/) aren't available):

```
skfde-open -d /dev/<device> -n <volume_name>
```

To print only the skfde passphrase to the console without unlocking any volumes:

```
skfde-open -p
```

To test only a passphrase for a specific key slot:

```
skfde-open -d /dev/<device> -s <keyslot_number> -t
```

To use optional parameters, example, use an external luks header:

```
skfde-open -d /dev/<device> -- --header /mnt/luks-header.img
```

## Kill skfde passphrase for existing LUKS encrypted volume

To kill a skfde passphrase for existing *LUKS* encrypted volume you can use [skfde-enroll](https://github.com/agherzan/SoloKey-full-disk-encryption/blob/master/src/skfde-enroll) script, see `skfde-enroll -h` for help:

```
skfde-enroll -d /dev/<device> -s <keyslot_number> -k
```

## Enable skfde initramfs hook

**Warning: It's recommended to have already working [encrypted system setup](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system) with `encrypt` hook and non-skfde passphrase before starting to use `skfde` hook with skfde passphrase to avoid potential misconfigurations.**

Edit `/etc/mkinitcpio.conf` and add the `skfde` hook before or instead of `encrypt` hook as provided in [example](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration#Examples). Adding `skfde` hook before `encrypt` hook will allow for a safe fallback in case of skfde misconfiguration. You can remove `encrypt` hook later when you confim that everything is working correctly. After making your changes [regenerate initramfs](https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation):

```
sudo mkinitcpio -P
```

Reboot and test your configuration.
