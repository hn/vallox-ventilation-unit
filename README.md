
# Vallox Ventilation Unit

## Preamble

Vallox produces highly efficient ventilation units for home and office use. Their current line of products can be controlled
both via a traditional control panel and a web frontend. A cloud service, for remote control and updates, is offered as well.

## Hardware

The ventilation unit uses a [STM32F4](https://www.st.com/en/microcontrollers-microprocessors/stm32f4-series.html)
microprocessor (ARM Cortex M4F).

## Software

The firmware of the device is available at the [Vallox Cloud Website](https://cloud.vallox.com/) as a
single binary file [HSWUPD.BIN](http://firmware.vallox.com/HSWUPD.BIN). All
changes are listed in the [changelog](http://cloud.vallox.com/changelog.txt).

Development firmware files can be found for [alpha](http://firmware.vallox.com/alpha/HSWUPD.BIN),
[beta](http://firmware.vallox.com/beta/HSWUPD.BIN) and [insider](http://firmware.vallox.com/insider/HSWUPD.BIN) stages.

### Unpack firmware

The firmware file HSWUPD.BIN contains several (nested) sections of data. Each
header and section is CRC-checked with CRC16/MODBUS.
With [unpack-vallox-firmware.pl](unpack-vallox-firmware.pl) one can unpack the file:

```
$ ./unpack-vallox-firmware.pl -w HSWUPD.BIN-2.0.2

Warning: Alpha Status, various things are unknown and/or wrong!

      0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 01 00 00 B1 43 35 00 D6 83 84 8A 02 00 9F 17
(0)==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC
      0                                                                             3490737 D6 83      166532 9F 17
Writing output file 'section-0-0000000-3490737.bin'

     24 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 01 00 01 60 8A 02 00 67 6C 60 8A 02 00 6E C6
(1)==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC
     36                                                                              166496 67 6C      166496 6E C6
Writing output file 'section-1-0000036-0166496.bin'
Unknown trailing bytes: 00 00 00 00 E2 C8 01 00 CE 0A 1C 00 CE 0A 1C 00

  28AB8 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 01 00 03 BE C8 01 00 4E 1C BE C8 01 00 C2 1C
(1)==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC
 166584                                                                              116926 4E 1C      116926 C2 1C
Writing output file 'section-1-0166584-0116926.bin'

  4539A 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 01 00 02 C8 41 1A 00 AD A2 C8 41 1A 00 39 4E
(1)==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC
 283546                                                                             1720776 AD A2     1720776 39 4E
Writing output file 'section-1-0283546-1720776.bin'

 1E9586 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 02 00 00 2B AE 16 00 F7 F1 5C 69 05 00 84 10
(1)==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC
2004358                                                                             1486379 F7 F1      354652 84 10
Writing output file 'section-1-2004358-1486379.bin'

 1E95AA 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 02 00 01 38 69 05 00 3C 26 38 69 05 00 97 A9
(2)==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC
2004394                                                                              354616 3C 26      354616 97 A9
Writing output file 'section-2-2004394-0354616.bin'
Unknown trailing bytes: 00 00 00 00 00 00 00 00 BF 44 11 00 BF 44 11 00

 23FF16 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 00 00 02 00 02 00 02 9B 44 11 00 84 62 9B 44 11 00 CA C7
(2)==== -------------Unknown/Reserved------------ -----Version----- ----Type--- ----Size--- -CRC- -DataStart- -hCRC
2359062                                                                             1131675 84 62     1131675 CA C7
Writing output file 'section-2-2359062-1131675.bin'
```

### Firmware analysis

Further examination reveals the following file layout and content:

```
          Filename                       Type-Subtype  Content

.-------- section-0-0000000-3490737.bin  0001-0000     Container
| ------- section-1-0000036-0166496.bin  0001-0001     PKG
| ------- section-1-0166584-0116926.bin  0001-0003     ESW
| ------- section-1-0283546-1720776.bin  0001-0002     GFX
| .------ section-1-2004358-1486379.bin  0002-0000     Container
| | ----- section-2-2004394-0354616.bin  0002-0001     ISW
| | ----- section-2-2359062-1131675.bin  0002-0002     TXT
```

`PKG` likely is the software updater for the device itself.

`ESW` likely is the code for the LCD control panel.

`GFX` contains raw icon data for the LCD control panel. Upload section file to https://rawpixels.net/ and see
yourself (width=50, height=2000, format=RGB32).

`ISW` likely is the code/webserver for the web gui and cloud ('ISW' = 'internet software'?).

`TXT` contains a FAT file system with HTML/CSS/PNG web gui data.

### ToDo

Sections with subtype `0001` contain 16 trailing bytes with unknown meaning (something,
len, len). These bytes are not CRC-checked.

