# Kingroon KP3SPro V2 и KLP1 руководство по созданию образа системы и перепрошивке

## Причины
  - Realtek 8723BS работает некорректно. Это приводит к перегрузке системы. Скорость передачи данных может быть очень низкой и нестабильной. 
    Иногда соединение прерывается. Есть альтернатива [Realtek 8723BS driver](https://github.com/youling257/rockchip_wlan). 
    Но если вы захотите скомпилировать его с текущим ядром, у вас ничего не получится, потому что нет заголовков ядра с нужной версией,
    совместимой с загруженным ядром. Альтернативный драйвер загружается быстрее и работает стабильнее.
    Он не обеспечивает максимальную скорость, но обеспечивает стабильность.
  - Альтернативный драйвер дает возможность переключать каналы и т.д..
  - Система выглядит так, как будто она использовалась с разными версиями mcu, имеет множество странных служб и неправильных настроек (например, поврежденные файлы конфигурации logrotate).
  - Kingroon поддержка не помогла. Они просто сказали: "Вы можете сами купить приемник сигнала Wi-Fi, чтобы усилить сигнал. В этом случае эффект должен быть лучше". Конечно, я могу купить другой 
    адаптер и, конечно, другой принтер. Но в него уже встроен wifi-адаптер, и есть способ заставить его работать лучше, так почему бы и нет?
  - Я хочу углубиться в процесс настройки, чтобы поднять свой опыт.

## Требования

  - Кабель USB Type C предназначен для подключения принтера к ПК через последовательный порт.
  - Kingroon KP3SPro V2 (KLP1) с Cheetah V2.0 Motherboard (**Внимание!. Cheetah V2.2 имеет некоторые отличия [difference](#Difference-between-V2-hardware).**)
  - Плата в экструдере должна быть распознана операционной системой принтера как RP2040 (OpenMoko, Inc. rp2040)
  - MKS EMMC Adapter V1.0 или его аналог( у многих шел в комплекте с принтером). **Можно изменить системный образ, не разбирая принтер.** [здесь](#booting-from-USB-flash)
  - microSD устройство для чтения карт памяти, подходящее для работы с EMMC (см. выше)
  - Virtual Machine или ПК с Linux (i.e. Ubuntu/Xubuntu) и установленным docker  [install docker in ubuntu](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
  - Способность решать распространенные проблемы Linux (пропущенные зависимости, программное обеспечение и так далее).
  - Время и терпение :)

## Начнем

### Создание собственного образа Armbian 

**Не хотите собирать? Попробуйте [это](https://github.com/Lebensgefahr/kingroon_kp3s_pro_v2/releases/latest)**. Klipper, Moonraker, Fluidd, printer.cfg и все, что описано в этой статье, включено в нее.

**репозиторий mkspi не обновлен, и процесс сборки завершится ошибкой. Попробуйте выполнить следующие действия https://github.com/Lebensgefahr/kingroon_kp3s_pro_v2/issues/3#issuecomment-2333484221**
Прежде всего, клонируйте [mkspi repository](https://github.com/redrathnure/armbian-mkspi) и создайте свой собственный образ Armbian. Предполагается, что docker уже установлен, и вы можете устранить любые проблемы, вызванные отсутствующими зависимостями.

```bash
mkdir Kingroon && cd Kingroon && git clone https://github.com/redrathnure/armbian-mkspi && 
cd armbian-mkspi && 
./compile.sh
```
<details>
  <summary>Параметры компиляции могут быть примерно такими, как показано на рисунках ниже.</summary>

  ![Select the kernel configuration](./pictures/armbian-mkspi_1.png)
  ![Select the target board](./pictures/armbian-mkspi_2.png)
  ![Select the target kernel branch](./pictures/armbian-mkspi_3.png)
  ![Select the target OS](./pictures/armbian-mkspi_4.png)
  ![Select the target image type](./pictures/armbian-mkspi_5.png)
  ![Select the target image type](./pictures/armbian-mkspi_6.png)

</details>

Теперь вам просто нужно набраться терпения (это займет около часа, в зависимости от быстродействия вашего ПК).
В результате сборки вы получите несколько файлов в выходном каталоге, как показано на рисунке.

<details>
  <summary>output directory tree</summary>

  ![Tree of the output directory](./pictures/armbian-mkspi_tree.png)

  Необходимый пакет для сборки драйвера Realtek 8723BS находится в каталоге debs:

  **linux-headers-current-rockchip64_24.2.0-trunk_arm64__6.1.74-S8fd7-Dfae2-P0da6-Cb86cHfe66-HK01ba-Vc222-B6a41-R448a.deb**

  Изображение Armbian находится в каталоге images:

  **Armbian-unofficial_24.2.0-trunk_Mkspi_jammy_current_6.1.74.img**
</details>

### Загрузка с USB флэшки
Если вы не хотите разбирать принтер или у вас нет адаптера emmc, вы можете воспользоваться USB-накопителем.
Подготовьте USB-накопитель.:

```bash

sudo dd if=$(ls armbian-mkspi/output/images/*.img) of=/dev/sdb bs=1M status=progress && sync
```
Пользователи Windows могут воспользоваться программой BalenaEtcher для записи образа на флэшку.

И скопируйте образ armbian куда-нибудь в корневой раздел этой флешки, чтобы он был доступен после загрузки.
Затем нам нужно загрузить принтер с этой флешки. Процесс автозагрузки Uboot bootloader может быть прерван нажатием любой клавиши. Но по умолчанию для этого нет задержки загрузки. Поэтому вам нужно нажимать любую клавишу слишком быстро, и иногда это срабатывает. Для этого вам нужно запустить программу последовательной связи, такую как minicom (для windows можно использовать Putty):

```bash

minicom -b 1500000 -D /dev/ttyUSB0
```
Скорость передачи данных должна составлять 1500000 бод, чтобы правильно просматривать booting log.

Затем перезагрузите принтер и начните нажимать на любую клавишу как можно быстрее :-) Если не удалось, перезагрузитесь и попробуйте нажимать быстрее.
Вы можете перезагрузить принтер
через ssh (ssh mks@192.168.1.15 "reboot") и удерживать кнопку ESC в окне терминала (проще, чем нажимать клавиши).
В случае успеха вы увидите приглашение uboot prompt:
```
Hit any key to stop autoboot:  0 
=>  
=>  
```

Измените переменную окружения boot_targets:

```
setenv boot_targets "usb0 mmc1 mmc0 pxe dhcp" 
```
По умолчанию первым загрузочным устройством является mmc1.
И напечатайте команду "boot".
Когда он загрузится, вам следует выполнить указанные действия (создать пароль root, имя пользователя и т.д.). После этого вы можете использовать dd для развертывания образа armbian в /dev/mmcblk1. Перезагрузитесь и повторите предыдущий шаг.
### Создание резервной копии EMMC и подготовка ее к первой загрузке

Снимите нижнюю крышку вашего KP3SProV2 (KLP1) и открутите два винта, которыми крепится модуль EMMC.
Вставьте карту EMMC в адаптер microSD (входит в комплект поставки) и вставьте ее в компьютер.
Некоторые адаптеры не работают с адаптером Makerbase EMMC-microSD. Например, не работает Kingston MobiLite G4.
<details>
  <summary>А это работает</summary>

  ![А это работает](./pictures/SDCardAdapter.png)
</details>

После вставки EMMC в USB на выходе lsblk появляется новое блочное устройство, подобное /dev/sdb:

![lsblk](./pictures/lsblk_emmc_1.png)

Создайте резервную копию вашей текущей системы:

```bash

mkdir backup && 
sudo dd if=/dev/sdb of=./backup/backup.img bs=1M status=progress && 
sync
```
Этот образ содержит все файлы вашей текущей системы, и он понадобится на следующих шагах, поэтому мы монтируем его сразу после завершения dd.

```bash

sudo losetup --partscan --find --show ./backup/backup.img
```
В Xubuntu он будет автоматически монтироваться в /media/$USER/, и все команды будут указываться с учетом этого пути.

Разверните созданный образ Armbian на /dev/sdb

```bash

sudo dd if=$(ls armbian-mkspi/output/images/*.img) of=/dev/sdb bs=1M status=progress && sync
```
Он снова автоматически подключится после завершения dd.
Теперь нам нужно скопировать пакет linux-headers, старый файл dtb и старые конфигурации в EMMC (с новым dtb wifi не работает).

linux-headers package:
```bash

sudo cp $(ls armbian-mkspi/output/debs/linux-headers*.deb) /media/$USER/armbi_root/root/
```
old dtb file:
```bash

sudo mv /media/$USER/armbi_boot/dtb/rockchip/rk3328-roc-cc.dtb /media/$USER/armbi_boot/dtb/rockchip/rk3328-roc-cc.dtb.bck && 
sudo cp /media/$USER/BOOT/dtb/rockchip/rk3328-roc-cc.dtb /media/$USER/armbi_boot/dtb/rockchip/rk3328-roc-cc.dtb
```
Старые конфигурации (проверьте GUID в поле путь к смонтированному образу старой системы):
```bash

sudo cp -a /media/$USER/4148ed1f-7865-4fd6-84b0-9564c15dbeac/home/mks/printer_data /media/$USER/armbi_root/root/
```
Теперь мы готовы снова подключить EMMC к принтеру, загрузить его и выполнить первый вход в систему.
Первый вход в систему мы должны выполнить от имени пользователя root и с паролем 1234 (по умолчанию для официального образа Armbian).
### Первая загрузка и сборка kernel module

Адаптер Ethernet должен работать, чтобы вы могли подключить его к своему маршрутизатору и попробовать войти с правами root через ssh, если он не отключен.
Вместо этого вы можете использовать кабель USB type C и подключить принтер к пк (разъем usb type-c расположен на передней панели принтера KP3SProV2, для KLP1 необходимо снять крышку подвала и подключиться непосредственно к разъему на плате).
Затем вы можете использовать что-то вроде minicom или putty для подключения к последовательной консоли принтера.
После того, как все подключено, вы можете включить принтер и запустить minicom.

```bash

minicom -b 115200 -D /dev/ttyUSB0
```

Если все идет так, как должно быть, вы можете увидеть что-то подобное в окне терминала:
![Console output](./pictures/serial_console_layout_1.png)

Через несколько минут нажмите enter несколько раз, и вы получите приветствие для входа в систему. В противном случае попробуйте выключить и снова включить принтер. 
После выключения принтера подождите, пока погаснут все светодиоды, особенно светодиоды на материнской плате.
Вы можете увидеть это через нижние отверстия для охлаждения на вашем столе.
Это важно, потому что блок питания продолжает подавать на него энергию во время разрядки конденсаторов.
Войдите в систему с правами root и паролем 1234 и ответьте на все вопросы. 
Это создаст нового пользователя (я использовал mks с паролем makerbase, как и должно быть из коробки).
Вы можете попробовать подключиться по беспроводной сети, но у меня это не работает. Поэтому я пропустил этот этап.
Теперь вы можете установить проводное соединение вручную и подключиться к принтеру через ssh. 
Я подключил принтер к ноутбуку и использую его как маршрутизатор для принтера.

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

Заморозьте важные пакеты:

```bash

armbian-config
```
Choose System -> Freeze (Disable Armbian kernel packages)

Создайте файл sudoers, чтобы использовать sudo без пароля:

```bash

sudo bash -c 'cat <<EOF >/etc/sudoers.d/mks
mks    ALL=NOPASSWD: ALL
EOF'
```

Скомпилируйте и установите новый драйвер [Armbian documentation](https://docs.armbian.com/User-Guide_Advanced-Features/#how-to-build-a-wireless-driver):
```bash

apt-get install -y libelf-dev &&
dpkg -i /root/linux-headers*.deb && 
git clone https://github.com/youling257/rockchip_wlan &&
cd rockchip_wlan/rtl8723bs &&
make ARCH=arm64
```

Проверьте, работает ли скомпилированный модуль:
```bash

rmmod r8723bs &&
insmod 8723bs.ko
```

Если все в порядке, то в dmesg будет что-то вроде этого:
![dmesg layout](./pictures/dmesg_8723bs.png)

Теперь вы можете установить его в том же месте, где находится старый:

```bash

make -B MODDESTDIR=/lib/modules/$(uname -r)/kernel/drivers/staging/rtl8723bs/ install
```
Внесите старый драйвер в modprobe blacklist:

```bash

sudo bash -c 'cat <<EOF >/etc/modprobe.d/blacklist-r8723bs.conf
blacklist r8723bs
EOF'
```

### Настройки сети

Теперь вы можете перезагрузить принтер, выполнив команду reboot, чтобы проверить, загружается ли новый модуль.
После перезагрузки вы можете попробовать подключиться к беспроводной сети. Создайте файл wpa_supplicant.conf:

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
Run wpa_cli and enter the following commads:
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

### Установка klipper, moonraker, fluidd

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

<details>
  <summary>How to get an actual firmware file name for mcu based on MB</summary>
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

### Final

Recalibrate mesh and that is all. Now you can uninstall linux-headers to free some space. 
But it is good to have this package at hand in the target system. Before you turn the bottom cover back recommend you
to make a backup image of your system as described in the beginning.
Thanks for reading.

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

