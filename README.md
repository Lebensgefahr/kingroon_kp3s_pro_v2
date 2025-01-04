# Kingroon KP3SPro V2 system image building and flashing tutorial

## Reasons
  - Realtek 8723BS is not working properly. It overloads the system. Bitrate can be very valueable and unstable. 
    Sometimes connection hanged. There is an alternative [Realtek 8723BS driver](https://github.com/youling257/rockchip_wlan). 
    But if you want to compile it with the current kernel you will fail because there is no kernel headers with the right version 
    compatible with the loaded kernel. Alternative driver is loading faster and works more stable.
    It gives no highest speed but it gives a stability.
  - Alternative driver gives an ability to change channel etc.
  - System looks like it was used with different versions of mcu, has a lot of strange services and misconfigurations (i.e. damaged logrotate configuration files).
  - Kingroon support didn't help. They just said "You can buy a wifi signal receiver yourself to increase the signal. In this case, the effect should be better." Of course i can buy another adapter and of course another printer. But it is already has embeded wifi adapter and there is a way to make it work better so why not?
  - I want to dig deep into the setting process to develop my experience.

## Requirements

  - USB Type C cable to connect the printer to PC for serial port connection.
  - Kingroon KP3SPro V2 with Cheetah V2.0 Motherboard (**WARNING. Cheetah V2.2 has some [difference](#Difference-between-V2-hardware).**)
  - Plate in the extruder should be recognized in the printer OS as RP2040 (OpenMoko, Inc. rp2040)
  - MKS EMMC Adapter V1.0 or analog (supplied included). **It is possible to change system image without printer disassembling check** [here](#booting-from-USB-flash)
  - microSD card reader suitable to work with EMMC (read below)
  - Virtual Machine or PC with Linux (i.e. Ubuntu/Xubuntu) and docker installed [install docker in ubuntu](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
  - Ability to solve common linux problems (missed dependencies, software and so on).
  - Time and patience

## Let's start

### Building your own Armbian image

**Don't want to build? Try this [one](https://github.com/Lebensgefahr/kingroon_kp3s_pro_v2/releases/latest)**. Klipper, Moonraker, Fluidd, printer.cfg and everything described in this article are included.

**mkspi repo is not up to date and building process will fail. Try to follow this steps https://github.com/Lebensgefahr/kingroon_kp3s_pro_v2/issues/3#issuecomment-2333484221**
First of all clone [mkspi repository](https://github.com/redrathnure/armbian-mkspi) and build your own Armbian image. Assumed docker is already installed and you can resolve any issues caused by missing dependencies.

```bash
mkdir Kingroon && cd Kingroon && git clone https://github.com/redrathnure/armbian-mkspi && 
cd armbian-mkspi && 
./compile.sh
```
<details>
  <summary>Compile options could be something like on pictures below.</summary>

  ![Select the kernel configuration](./pictures/armbian-mkspi_1.png)
  ![Select the target board](./pictures/armbian-mkspi_2.png)
  ![Select the target kernel branch](./pictures/armbian-mkspi_3.png)
  ![Select the target OS](./pictures/armbian-mkspi_4.png)
  ![Select the target image type](./pictures/armbian-mkspi_5.png)
  ![Select the target image type](./pictures/armbian-mkspi_6.png)

</details>

Now you just need to have patience (it takes about an hour depending on your PC hardware).
As the result of building you will get some files in an output directory as shown on a picture.

<details>
  <summary>output directory tree</summary>

  ![Tree of the output directory](./pictures/armbian-mkspi_tree.png)

  The required package to build Realtek 8723BS driver is located in debs directory:

  **linux-headers-current-rockchip64_24.2.0-trunk_arm64__6.1.74-S8fd7-Dfae2-P0da6-Cb86cHfe66-HK01ba-Vc222-B6a41-R448a.deb**

  The Armbian image is located in images directory:

  **Armbian-unofficial_24.2.0-trunk_Mkspi_jammy_current_6.1.74.img**
</details>

### Booting from USB flash
In case you do not want to disassemble the printer or you do not have an emmc adapter you can use USB flash drive.
Prepare USB flash drive:

```bash

sudo dd if=$(ls armbian-mkspi/output/images/*.img) of=/dev/sdb bs=1M status=progress && sync
```
And copy armbian image somewhere to root partiotion of this flash drive to have it after booting available.
Then we need to boot printer from this USB flash drive. Uboot bootloader autoboot process can be interrupted by hiting any key. But it has no bootdelay for that by default. So you need to hiting any key too fast and sometimes it works. To do that you need to start serial communication program like picocom:

```bash
picocom --b 1500000 /dev/ttyUSB0

```
Baud rate should be 1500000 to see booting log corectly.
Then reboot your printer and start hiting an any key as fast as you can :-) If failed reboot and try to hit faster. You can reboot your printer
through ssh (ssh mks@192.168.1.15 'reboot') and hold ESC button in terminal window (easier than hiting keys).
If success you will see an uboot prompt:
```
Hit any key to stop autoboot:  0 
=>  
=>  
```

Change boot_targets environment variable:

```
setenv boot_targets "usb0 mmc1 mmc0 pxe dhcp" 
```
By default the first booting device is mmc1.
And type "boot".
When it boots you should follow the provided steps (create root password, user etc). After that you can use dd to deploy armbian image to /dev/mmcblk1. Reboot and repeat the previous step. 
### Creating EMMC backup and preparing it for the first boot

Remove the bottom cover of your KP3SProV2 and unscrew two screws fastening the EMMC module.
Put the EMMC card into microSD adapter (supplied included) and insert it into your PC.
Some adapters are not working with Makerbase EMMC-microSD adapter. For example Kingston MobiLite G4 is not working.
<details>
  <summary>But this works</summary>

  ![But this one works](./pictures/SDCardAdapter.png)
</details>

After insertion of EMMC into USB appears a new block device like /dev/sdb in lsblk output:

![lsblk](./pictures/lsblk_emmc_1.png)

Create backup of your current system:

```bash

mkdir backup && 
sudo dd if=/dev/sdb of=./backup/backup.img bs=1M status=progress && 
sync
```
This image contains all files of your current system and it will be needed during next steps so we mount it right after dd completed.

```bash

sudo losetup --partscan --find --show ./backup/backup.img
```
In Xubuntu it will mount automatically to /media/$USER/ and commands are assumed that.

Deploy an builded Armbian image to /dev/sdb

```bash

sudo dd if=$(ls armbian-mkspi/output/images/*.img) of=/dev/sdb bs=1M status=progress && sync
```
It will mount automatically again after dd finishes.
Now we need to copy the linux-headers package and an old dtb file and old configurations to EMMC (with a new dtb wifi is not working).

linux-headers package:
```bash

sudo cp $(ls armbian-mkspi/output/debs/linux-headers*.deb) /media/$USER/armbi_root/root/
```
old dtb file:
```bash

sudo mv /media/$USER/armbi_boot/dtb/rockchip/rk3328-roc-cc.dtb /media/$USER/armbi_boot/dtb/rockchip/rk3328-roc-cc.dtb.bck && 
sudo cp /media/$USER/BOOT/dtb/rockchip/rk3328-roc-cc.dtb /media/$USER/armbi_boot/dtb/rockchip/rk3328-roc-cc.dtb
```
Old configurations (check GUID in path to the mounted image of an old system):
```bash

sudo cp -a /media/$USER/4148ed1f-7865-4fd6-84b0-9564c15dbeac/home/mks/printer_data /media/$USER/armbi_root/root/
```
Now we are ready to turn back EMMC to the printer boot it and make the first login atempt.
The first login we should do as root and with password 1234 (default for Armbian official image).

### First boot and compiling kernel module

Ethernet adapter should work so you can connect it to your router and try to enter with root through ssh if it is not disabled.
Instead you can use USB type C cable and connect the printer to your PC (usb type-c socket is located on the front panel of the printer).
Then you can use something like picocom to connect to the serial console of the printer.
After is everything connected you can turn printer on and start picocom.

```bash
picocom --b 1500000 /dev/ttyUSB0

```

If everything is go as it should be you can see something like this in a terminal window:
![Console output](./pictures/serial_console_layout_1.png)

After some minutes hit enter few times and you can get a greeting to login. Otherwise try to turn the printer off and on. 
After printer is turned off wait until all LEDs are turned off especially LEDs on the motherboard.
You can see it throught the bottom cooler holes on your table.
This is important because the power supply keeps giving the energy to it during its capacitors are discharging.
Login with root and password 1234 and answer all questions. 
It will create new user (I used mks with password makerbase as it should be from the box).
You can try to connect via wireless but for me it doesn't work. So I skiped this stage.
Now you can set wired connection manually and connect to the printer though ssh. 
I connected the printer to laptop and use it as a router for the printer.

### Configure wired connection manually

<details>
  <summary>Configure laptop as router and printer as client manually</summary>

  Laptop:

  ```bash

  #protect interface of beeing managed by network manager
  nmcli device set enp43s0 managed off 
  #turn on NAT for printer where 192.168.2.2 is a printer ethernet interface address 
  #and 192.168.1.11 is the address of the laptop given by WiFi router
  sudo iptables -t nat -A POSTROUTING -s 192.168.2.2 -j SNAT --to 192.168.1.11
  #add address to the laptop ethernet interface
  sudo ip addr add 192.168.2.1/24 dev enp43s0 
  #enable ip forwarding in the kernel
  sudo sysctl net.ipv4.ip_forward=1 
  ```  
  Printer:

  ```bash

  nmcli device set eth0 managed off
  #set ip address on ethernet interface
  ip addr add 192.168.2.2/24 dev eth0 
  #set default route through the laptop
  ip route add default via 192.168.2.1
  ```
</details>

To have a key authorization you can run:

```bash

  ssh-copy-id mks@192.168.2.2
```

Freeze important packages:

```bash

armbian-config
```
Choose System -> Freeze (Disable Armbian kernel packages)

Create sudoers file to have sudo without a password:

```bash

sudo bash -c 'cat <<EOF >/etc/sudoers.d/mks
mks    ALL=NOPASSWD: ALL
EOF'
```

Compile and install new driver [Armbian documentation](https://docs.armbian.com/User-Guide_Advanced-Features/#how-to-build-a-wireless-driver):
```bash

apt-get install -y libelf-dev &&
dpkg -i /root/linux-headers*.deb && 
git clone https://github.com/youling257/rockchip_wlan &&
cd rockchip_wlan/rtl8723bs &&
make ARCH=arm64
```

Check if compiled module works:
```bash

rmmod r8723bs &&
insmod 8723bs.ko
```

If everything is ok in dmesg will be something like this:
![dmesg layout](./pictures/dmesg_8723bs.png)

Now you can install it at the same place where an old is located:

```bash

make -B MODDESTDIR=/lib/modules/$(uname -r)/kernel/drivers/staging/rtl8723bs/ install
```
Put an old driver to modprobe blacklist:

```bash

sudo bash -c 'cat <<EOF >/etc/modprobe.d/blacklist-r8723bs.conf
blacklist r8723bs
EOF'
```

### Network settings

Now you can reboot your printer by executing reboot command to check if the new module is loading.
After reboot you can try to connect to a wireless network.

You can try to connect to Wi-Fi network whith this command:
```bash
nmcli dev wifi connect <YOUR_SSID> password <YOUR_PASSWORD>
```
Or you can use armbian-config.

Another way which is 100% working on Kingroon default image:

Create wpa_supplicant.conf file:

```bash
sudo bash -c 'cat <<EOF >/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
EOF'

```
Enable wpa_supplicant on wlan0 interface:

```bash

sudo systemctl enable wpa_supplicant@wlan0 &&
sudo systemctl start wpa_supplicant@wlan0
```
Run **wpa_cli** in console and enter the following commads ONE BY ONE finish with ENTER:
```
add_network
set_network 0 ssid "YOUR_SSID"
set_network 0 psk "YOUR_KEY"
set_network 0 key_mgmt WPA-PSK
set_network 0 proto WPA2
enable_network 0
save_config
quit
```
Enable DHCP on wlan0 interface
```bash
sudo bash -c 'cat <<EOF >/etc/network/interfaces.d/wlan0
auto wlan0
iface wlan0 inet dhcp
EOF'

```
Restart networking:
```bash

sudo systemctl restart networking
```


### Installation of klipper, moonraker, fluidd

Printer configuration files and systemd unit files you can find [here](files/userpatches/overlay)
Work under mks user. Clone and use kiauh as described [Here](https://github.com/redrathnure/armbian-mkspi):

```bash

git clone https://github.com/th33xitus/kiauh.git &&
./kiauh/kiauh.sh
```

Select software to install.

Klipper: 1->1->1->1

Moonraker: 2 

Fluidd: 4

After installation completed we need to compile new klipper firmware and 
binary [read here](https://www.klipper3d.org/RPi_microcontroller.html) and [here](https://github.com/makerbase-mks/MKS-THR36-THR42-UTC).
I tried to use a new klipper version with an old firmware but it is not completely compatible and throws an error.

All described is suitable for Raspberry Pi RP2040. You can check if it is exists with command lsusb.
It should be something like this:
```
Bus 001 Device 002: ID 1d50:614e OpenMoko, Inc. **rp2040**
```

#### Compile THR firmware and binary:

Run:
```bash

cd /home/mks/klipper && make clean && make menuconfig
```

<details>
  <summary>Select compiling options V2.0</summary>

  ![Select the target board](./pictures/klipper_fw_1.png)
</details>

<details>
  <summary>Select compiling options V2.2</summary>

  ![Select the target board](./pictures/rp2040_uart.png)
</details>


<details>
  <summary>Connect THR mcu as USB (for V2.2 version)</summary>
  You can disassembly an old mouse to get USB cable and JST-XH 2.5mm(2.54mm) connector.

  ![](./pictures/rp2040_v22_1.jpg)
  ![](./pictures/rp2040_v22_2.jpg)
  ![](./pictures/rp2040_v22_3.jpg)

  Before proceeding it is better to disconnect original cable from THR module (**WARNING!!! It is possible to burn out motherboard if printer is on
  during THR module disconnecting**).
  After than connect your own USB cable and turn printer on. To flash rp2040 you can proceed for the next step or do it manually 
  <details>
    <summary>Manual flashing</summary>
    <ol>
      <li>While holding down the "boot" button on the rp2040, plug in the USB cable to any PC that will automount a USB drive for you to access the files (Windows, Ubuntu Desktop, MAC, etc)</li>
      <li>If done and wired correctly, a drive named "RP1-RP2" will be connected.</li>
      <li>Copy the klipper.uf2 file to the "RP1-RP2" drive"</li>
      <li>The rp2040 will immediately reboot itself and load the new firmware as soon as the file transfer is complete. This is normal.</li>
      <li>Wait 30 seconds, then unplug the rp2040 and reinstall in the printer.</li>
    </ol>
  </details>

</details>


Check if your MCU is available by path /dev/serial/by-id/. Otherwise try to turn your printer off and on.
Instead of powering your printer off you can press RESET button under the cooler cover.
Flash MCU with compiled firmware:
```
make flash FLASH_DEVICE=/dev/serial/by-id/usb-Klipper_rp2040_05034E955CC76258-if00
```
If everything is ok:
![Flashing success](./pictures/klipper_flashing_success.png)

#### Compile firmware for MCU on motherboard (GD32F303VET6):

You can check current compiling settings in klippy.log for both mcu.

For example:
```
Loaded MCU 'mcu' 105 commands (v0.11.0-122-ge6ef48cd-dirty-20230330_000318-mkspi / gcc: (15:7-2018-q2-6) 7.3.1 20180622 (release) [ARM/embedded-7-branch revision 261907] binutils: (2.31.1-12+11) 2.31.1)
MCU 'mcu' config: ADC_MAX=4095 BUS_PINS_i2c1=PB6,PB7 BUS_PINS_i2c1a=PB8,PB9 BUS_PINS_i2c2=PB10,PB11 BUS_PINS_spi1=PA6,PA7,PA5 BUS_PINS_spi1a=PB4,PB5,PB3 BUS_PINS_spi2=PB14,PB15,PB13 BUS_PINS_spi3=PB4,PB5,PB3 CLOCK_FREQ=72000000 MCU=stm32f103xe PWM_MAX=255 RECEIVE_WINDOW=192 RESERVE_PINS_serial=PA10,PA9 SERIAL_BAUD=250000 STATS_SUMSQ_BASE=256 STEPPER_BOTH_EDGE=1
```

```bash

make menuconfig
```
<details>
  <summary>Select compiling options V2.0</summary>

  ![Select compiling options](./pictures/klipper_fw_3.png)
</details>

<details>
  <summary>Select compiling options V2.2</summary>

  ![Select compiling options](./pictures/v22_compiling_1.png)
</details>




```bash

make
```

#### Write firmware image to SD card in printer slot.

<details>
  <summary>Don't want to use external SD card reader or copying files manually?</summary>
When this article was written it works but later I can't repeat it. It throws an error something like "There is no SD card in the slot".
FatFS module included in klipper repository has no long file names support enabled.
We need to enable it.

Edit file:
```
mcedit /home/mks/klipper/lib/fatfs/ffconf.h
```
Set:
```
#define FF_USE_LFN		0
```
to:
```
#define FF_USE_LFN		1
```
Edit file:
```
mcedit /home/mks/klipper/scripts/spi_flash/fatfs_lib.py
```
Set:
```
char     name[13];
```
to:
```
char     name[255];
```
Add board defenition:

```
mcedit /home/mks/klipper/scripts/spi_flash/board_defs.py
```
Add the following lines to BOARD_DEFS dictionary:
```
    'kp3s_pro_v2': {
        'mcu': "stm32f103xe",
        'spi_bus': "swspi",
        'spi_pins': "PC8,PD2,PC12",
        'cs_pin': "PC11",
        'skip_verify': True,
        'firmware_path': "cheetah_v2.bin"
    }

```
![Select compiling options](./pictures/klipper_fw_4.png)

SD card should be in printer SD card slot at this moment.
Now run the following command:

```bash

./scripts/flash-sdcard.sh /dev/ttyS0 kp3s_pro_v2
```
Beeper will make the sound.

Result:

![Select compiling options](./pictures/klipper_fw_5.png)

Ignore this error.
Now just need to turn printer off and on with poweroff command.
After establishing ssh connection run the following command from the klipper directory:
```bash

 ./scripts/flash-sdcard.sh -c /dev/ttyS0 kp3s_pro_v2
```
It will compare flashed firmware with its image on the host system. If everything is ok then result will be:

![Select compiling options](./pictures/klipper_fw_6.png)

</details>

After building copy klipper.bin file to SD card with name **cheetah_v2.bin** (filename is important). For cheetah V2.2 motherboard
filename should be **cheetah_v2_2.bin**
Put SD card into printer card slot turn it off and on.


#### Install binary and systemd unit file:

Check if the device in /dev/serial/by-id is available. In my case it was not. So turn the printer off and on.

Now copy an old configuration files from the image mounted on the host machine:
```bash

scp /media/$USER/4148ed1f-7865-4fd6-84b0-9564c15dbeac/home/mks/printer_data/config/MKS_THR.cfg \
mks@192.168.1.15:/home/mks/printer_data/config/ &&
scp /media/$USER/4148ed1f-7865-4fd6-84b0-9564c15dbeac/home/mks/printer_data/config/moonraker.conf \
mks@192.168.1.15:/home/mks/printer_data/config/ &&
scp /media/$USER/4148ed1f-7865-4fd6-84b0-9564c15dbeac/home/mks/printer_data/config/printer.cfg \
mks@192.168.1.15:/home/mks/printer_data/config/
```
I suggest you replace env files for systemd from this repository becuase service logs are located inside the printer_data directory
but it is better to put them to RAM drive mounted to /var/log. So copy them to the printer and replace in ~/printer_data/systemd directory.

Now we need to make some changes in systemd files.

Run:
```bash

sudo EDITOR=mcedit systemctl edit klipper.service
```

And put the following content right in the place for them (read file content):

```
[Service]
LogsDirectory=klipper
RuntimeDirectory=klipper
```
Save changes by hiting F2 and exit.

Do the same for moonraker:

```bash
sudo EDITOR=mcedit systemctl edit moonraker.service
```
```
[Service]
LogsDirectory=moonraker
```
Now stop all services, remove logs from printer_data directory and start them again.

```bash
sudo systemctl stop moonraker.service klipper.service && 
rm -rf ~/printer_data/logs/{klip*,moon*} &&
sudo systemctl start moonraker.service klipper.service
```
Check logs in /var/log for errors.
I didn't copy an old fluidd configuration and macroses but you can do that.

### STLINK

#### How to get firmware file name from bootloader

<details>
  <summary>Expand</summary>
  If you have st-link programmer you can use it to dump bootloader and determine firmware file name with strings utility.
  St-link can be connected to the pins shown on the picture.

  ![SWD pins](./pictures/cheetah_v2_swd_pins.jpg)

Command for openocd should be like this:

```bash
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c init -c "reset halt" -c "flash read_bank 0 firmware.bin 0" -c "reset"

```
Firmware filename can be determined with strings:
  ![Firmware name](./pictures/firmware_filename.png)

</details>


#### How to flash default kingroon bootloader

<details>
  <summary>Expand</summary>

Full flash image and bootloader image can be found [here](files/firmware).
Install openocd as a package or from the sources first.

Run openocd:
```bash
sudo openocd -f interface/stlink.cfg -f target/stm32f1x.cfg
```
This command can be finished with error message something like "wrong ID number".
It is because there is no stm32f103 on this board it has it's clone. Change ID in stm32f1x.cfg to match this criteria.

In another windown run telnet inside directory where flash or bootloader image is located:

```bash
telnet 127.0.0.1 4444
```
Execute commands in telnet session:

```
> flash banks
#0 : stm32f1x.flash (stm32f1x) at 0x08000000, size 0x00000000, buswidth 0, chipwidth 0
> stm32f1x mass_erase 0
Target not halted
stm32x mass erase failed
> halt
[stm32f1x.cpu] halted due to debug-request, current mode: Handler HardFault
xPSR: 0x21000003 pc: 0xfffffffe msp: 0xffffff90
> stm32f1x mass_erase 0
timed out waiting for flash
stm32x mass erase failed
jtag status contains invalid mode value - communication failure
Polling target stm32f1x.cpu failed, trying to reexamine
Examination failed, GDB will be halted. Polling again in 100ms
Previous state query failed, trying to reconnect
Polling target stm32f1x.cpu failed, trying to reexamine
[stm32f1x.cpu] Cortex-M4 r0p1 processor detected
[stm32f1x.cpu] target has 6 breakpoints, 4 watchpoints
> flash write_bank 0 firmware.bin
Padding at 0x08000bd7 with 1 bytes (bank write end alignment)
wrote 524288 bytes from file firmware.bin to flash bank 0 at offset 0x00000000 in 15.199426s (33.685 KiB/s)
>reset

```
After reset it should beep once (bootloader makes this beep).
</details>

#### Known issues

With stlink connected and powered on virtual end stop of X axis is not working !!!

### Final

Recalibrate mesh and that is all. Now you can uninstall linux-headers to free some space. 
But it is good to have this package at hand in the target system. Before you turn the bottom cover back recommend you
to make a backup image of your system as described in the beginning.
Thanks for reading.


### Additional changes

#### Inverse encoder rotation

It was annoying that the encoder works in reverse. When it is rotating CW it decreases values but it should increase.
All we need to do to fix that is to sweep its pins in printer.cfg. You can do it through fluidd interface in the Configuration tab.
```
#encoder_pins:^PE13,^PE14
encoder_pins:^PE14,^PE13
```
#### Turning on mesh fade

Add options to configuration file in bed_mesh section to phasing out bed_mesh adjustment. By default fade_end is 0 and it means it is turned off.
This options seamlessly disables the use of bed mesh. Otherwise, the curvature of the table will be kept throughout the entire height of the model.
Of course you should use values which is lower than the height of the model. Read [here](https://www.klipper3d.org/Bed_Mesh.html#mesh-fade).

In this example fading starts at 1 mm height and ends at 5 mm.
```
[bed_mesh]
fade_start: 1
fade_end: 5
```

#### Setup menu

After updating firmware of THR kingroon menu will dissapear. You can turn it back by comparing menu.cfg file from the image with the new one.
But don't edit it. You can put chages inside your printer.cfg file. Except one function. Kingroon added IP determination as a python code.

#### LEDs

There is a chain of three WS2812 on display PCB and you can use it for your needs like printer status signalization.
You can check leds.cfg as example. Printer changes it's color during homing/printing/heating etc.


### Additional information

#### rp2040 GPIO

<details>
  <summary>Expand</summary>

![GPIO layout](./pictures/gpio.jpg)

Configure this gpio as output_pin and you can check it with set_pin g-command

```
[output_pin gpio11]
pin: MKS_THR:gpio11

[output_pin gpio29]
pin: MKS_THR:gpio29

```

```
set_pin pin=gpio11 value=1
```
</details>

### Heatbreak cooler controller.

<details>
  <summary>Expand</summary>
  THR v1.0 plate has no mosfet for heatbreak cooler. You can install it by yourself as shown on the pictures below.
  I bought a mosfet module for Arduino cut it and solder it directly to GND 5V S pins.
  WARNING!!! 5V and S holes on mosfet module PCB are connected together. This connection should be broken before soldering.
  Pins GND Z+ should be cut as short as possible.

  ![Module](./pictures/mosfet/1.jpg)
  ![Cutting](./pictures/mosfet/2.jpg)
  ![Ready](./pictures/mosfet/3.jpg)
  ![Assembled](./pictures/mosfet/4.jpg)

After everything is assembled, it is enough to add the following to the printer config:

```
[heater_fan heatbreak_cooling_fan]
pin: MKS_THR:gpio11
heater: extruder
heater_temp: 50.0
```
</details>



### Difference between V2 hardware

<table>
  <tr>
    <th>V2.0</th>
    <th>V2.2</th>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <ul>
        <li>THR MCU connected via USB</li>
        <li>MCU on the motherboard connected via UART</li>
        <li>Thermal barrier cooler can't be controlled by THR MCU</li>
        <li>THR plate can be flashed without disassembling</li>
        <li>It has Realtek 8723BS Wi-Fi adapter</li>
        <li>Firmware file name written to SD card for flashing mcu should be cheetah_v2.bin</li>
        <li>Has a supercapacitor that allows the operating system to shutdown correctly. System is online about 15 sec after switch was turned off. State can be checked by gpioget 2 16 (0 power is on/1 power is off)</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <ul>
        <li>THR MCU connected via UART</li>
        <li>MCU on the motherboard connected via USB</li>
        <li>Thermal barrier cooler can be controlled by THR MCU</li>
        <li>THR plate can be flashed after disassembling and soldering pins to USB contacts (you can see it on the picture below marked with 5V GND D+ D-)</li>
        <li>It has a different Wi-Fi adapter</li>
        <li>Firmware file name written to SD card for flashing mcu should be cheetah_v2_2.bin</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td colspan=2 align="center">Motherboard</td>
  <tr>
    <td><img src="./pictures/diff/MB2.0.jpg"  alt="1" width = 360px height = 360px ></td>
    <td><img src="./pictures/diff/MB2.2.jpg" alt="2" width = 360px height = 360px></td>
  </tr>
  <tr>
    <td colspan=2 align="center">THR</td>
  <tr>
  <tr>
    <td><img src="./pictures/diff/THR_V1.0_1.jpg" alt="3" width = 360px></td>
    <td><img src="./pictures/diff/THR_V2.0_1.jpg" align="right" alt="4" width = 360px></td>
  </tr>
  <tr>
    <td><img src="./pictures/diff/THR_V1.0_2.jpg" alt="3" width = 360px></td>
    <td><img src="./pictures/diff/THR_V2.0_2.jpg" align="right" alt="4" width = 360px></td>
  </tr>
</table>

