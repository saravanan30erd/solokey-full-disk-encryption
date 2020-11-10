# SoloKey Full Disk Encryption

This project leverages a [SoloKey](https://wiki.archlinux.org/index.php/Solo) [HMAC Challenge-Response](https://github.com/solokeys/solo-python#challenge-response) mode for creating strong [LUKS](https://gitlab.com/cryptsetup/cryptsetup) encrypted volume passphrases. It can be used in intramfs stage during boot process as well as on running system.

SoloKey uses two inputs, challenge and credential to generate the response. The response will be used as your LUKS encrypted volume passphrase.

This was only tested and intended for:

* [Arch Linux](https://www.archlinux.org/) and its derivatives
* [SoloKey](https://solokeys.com/)

Table of Contents
=================

   * [SoloKey Full Disk Encryption](#solokey-full-disk-encryption)
   * [Table of Contents](#table-of-contents)
   * [Prerequisites](#prerequisites)
   * [Install](#install)
      * [From Github using 'make'](#from-github-using-make)
   * [Configure](#configure)
      * [Create SoloKey credential](#create-solokey-credential)
      * [Edit /etc/skfde.conf file](#edit-etcskfdeconf-file)
      * [Enroll solokey passphrase to existing LUKS encrypted volume](#enroll-solokey-passphrase-to-existing-luks-encrypted-volume)
      * [Enable skfde initramfs hook](#enable-skfde-initramfs-hook)
   * [Usage](#usage)
      * [Format new LUKS encrypted volume using solokey passphrase](#format-new-luks-encrypted-volume-using-solokey-passphrase)
      * [Unlock LUKS encrypted volume protected by solokey passphrase](#unlock-luks-encrypted-volume-protected-by-solokey-passphrase)
   * [License](#license)
   * [Credits](#credits)

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

**Warning: It's recommended to have already working [encrypted system setup](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system) with `encrypt` hook and non-solokey passphrase before starting to use `skfde` hook with solokey passphrase to avoid potential misconfigurations.**

Refer [here](https://github.com/saravanan30erd/Arch-Linux-Installation-with-LUKS/blob/master/Notes.md) for Arch Linux installation with LUKS.

# Install

## From Github using 'make'

```
git clone https://github.com/saravanan30erd/solokey-full-disk-encryption
cd solokey-full-disk-encryption
make install
```

# Configure

## Create SoloKey credential

Plug the solokey and run the below command,

```
skfde-cred
```

You need to pass the solokey pin to authenticate the solokey and then press the solokey button to generate the credential.

```
~]# skfde-cred
Generate the SoloKey credential
Enter the SoloKey PIN: <pass pin>
Remember to press the SoloKey button if necessary
SoloKey credential : <credential>
```

## Edit /etc/skfde.conf file

Open the /etc/skfde.conf file and adjust it for your needs.

Example:

Provide the LUKS encrypted device,
```
SKFDE_LUKS_DEV="/dev/sda3"
```

LUKS encrypted volume name after unlocking,
```
SKFDE_LUKS_NAME="luks_root"
```

Challenge to generate solokey response, it can be text such as alphanumeric.
```
SKFDE_CHALLENGE="Bugn05DioqvVzQyFYhwD9EhRejXXAci"
```

Credential used to generate solokey response, use the credential created using `skfde-cred`.
```
SKFDE_CREDENTIAL="<credential>"
```

## Enroll solokey passphrase to existing LUKS encrypted volume

To enroll new solokey passphrase to existing *LUKS* encrypted volume you can use `skfde-enroll`,
see `skfde-enroll -h` for help:

```
skfde-enroll -d /dev/<device> -s <keyslot_number>
```

By default, it uses `keyslot 3` if you don't pass `-s <keyslot_number>`.

```
skfde-enroll -d /dev/sda3
```

**Warning: having a weaker non-solokey passphrase(s) on the same *LUKS* encrypted volume undermines the solokey passphrase value as potential attacker will always try to break the weaker passphrase. Make sure the other non-solokey passphrases are similarly strong or remove them.**

## Enable skfde initramfs hook

Edit `/etc/mkinitcpio.conf` and add the `skfde` hook before or instead of `encrypt` hook as provided in [example](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration#Examples). Adding `skfde` hook before `encrypt` hook will allow for a safe fallback in case of skfde misconfiguration. You can remove `encrypt` hook later when you confirm that everything is working correctly.

After making the changes, run the below command to regenerate the initramfs.

```
skfde-load
```

Reboot and test your configuration.

During the boot process, it will pause and you need to pass the solokey pin to authenticate the solokey.
Then press the solokey button.

# Usage

## Format new LUKS encrypted volume using solokey passphrase

To format new *LUKS* encrypted volume, you can use `skfde-format` which is wrapper over `cryptsetup luksFormat` command:

```
skfde-format --cipher aes-xts-plain64 --key-size 512 --hash sha512 /dev/<device>
```

## Unlock LUKS encrypted volume protected by solokey passphrase

To unlock *LUKS* encrypted volume on a running system, you can use `skfde-open` script,
see `skfde-open -h` for help.

By default, it uses `keyslot 3` if you don't pass `-s <keyslot_number>`.
```
skfde-open -d /dev/<device> -n <LUKS volume name>
```

```
skfde-open -d /dev/sda3 -n luks_vol1
```

To test only a passphrase for a specific key slot:

```
skfde-open -d /dev/<device> -s <keyslot_number> -t
```

# License

Licensed under

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or
  http://www.apache.org/licenses/LICENSE-2.0)

# Credits

- [fido2luks](https://github.com/shimunn/fido2luks)
- [yubikey-full-disk-encryption](https://github.com/agherzan/yubikey-full-disk-encryption)
