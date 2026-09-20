## 1. Board at a glance

- MCU module: **ESP32-S3-MINI-1**
- Native USB-C connected directly to the ESP32-S3 USB pins
- SPI-connected display connector with resistive touch panel
- I²C touch controller: **NS2009**, address **0x48**
- I²C temperature sensor: **TMP103**, address **0x70**
- I²C accelerometer: **SC7A20**, address **0x19**, with interrupt line
- External **Qwiic** connector on the same I²C bus
- **4 × SK6812MINI-E** addressable RGB LEDs in a daisy chain
- **6 × 13 keyboard matrix**
- IR transmit LED + IR receive phototransistor, wired to the MCU UART signals
- Battery and USB-VBUS voltage sensing through 1:2 resistor dividers
- BOOT and ENABLE/RESET pushbuttons

The red and green charge-status LEDs belong to the charger IC. No GPIO reaches
them.

---

## 2. GPIO quick reference

This is the most useful table for firmware.

| ESP32-S3 GPIO | Board net / function | Notes |
|---:|---|---|
| 0 | `BOOT` | BOOT pushbutton pulls low |
| 1 | `BATT_SENSE` | ADC1_CH0, half of `+BATT` |
| 2 | `VBUS_SENSE` | ADC1_CH1, half of USB `VBUS` |
| 3 | `DISPLAY_BACKLIGHT` / `BL_PWM` | Backlight, active low. Strapping pin (JTAG source select) |
| 4 | `DISPLAY_D/C` | Display data/command signal |
| 5 | `SPI_CLK` | Display SPI clock |
| 6 | `DISPLAY_RESET` | Display reset |
| 7 | `SPI_CS` | Display chip select |
| 8 | `SPI_MOSI` | Display SPI data out; named `SPI_SDA` on display connector |
| 9 | `SPI_MISO` | Display SPI data in; named `SPI_SDO` on display connector |
| 10 | `I2C_SCL` | Shared I²C clock |
| 11 | `I2C_SDA` | Shared I²C data |
| 12 | `ACCEL_IRQ` | SC7A20 `INT1` |
| 13 | `TP_IRQ` | NS2009 touch-controller IRQ |
| 14 | `NEOPIXEL` | Data input for first SK6812MINI-E, through 100 Ω |
| 15 | `COL12` | Keyboard matrix |
| 16 | `COL11` | Keyboard matrix |
| 17 | `COL10` | Keyboard matrix |
| 18 | `COL9` | Keyboard matrix |
| 19 | `USB_D-` | Native USB D- |
| 20 | `USB_D+` | Native USB D+ |
| 21 | `COL8` | Keyboard matrix |
| 26 | `COL7` | Keyboard matrix. **Disputed, see section 9** |
| 33 | `COL5` | Keyboard matrix |
| 34 | `COL4` | Keyboard matrix |
| 35 | `COL2` | Keyboard matrix |
| 36 | `COL1` | Keyboard matrix |
| 37 | `COL0` | Keyboard matrix |
| 38 | `ROW0` | Keyboard matrix |
| 39 | `ROW1` | Keyboard matrix |
| 40 | `ROW2` | Keyboard matrix |
| 41 | `ROW3` | Keyboard matrix |
| 42 | `ROW4` | Keyboard matrix |
| 43 | `UART_TX` | Also `IR_TX` |
| 44 | `UART_RX` | Also `IR_RX` |
| 45 | `ROW5` | Keyboard matrix. Strapping pin, boots pulled down |
| 46 | none | No board net on the MCU sheet. **Disputed, see section 9** |
| 47 | `COL6` | Keyboard matrix |
| 48 | `COL3` | Keyboard matrix |

### Keyboard matrix ordered lists

```text
ROWS: ROW0=GPIO38, ROW1=GPIO39, ROW2=GPIO40,
      ROW3=GPIO41, ROW4=GPIO42, ROW5=GPIO45

COLS: COL0=GPIO37, COL1=GPIO36, COL2=GPIO35, COL3=GPIO48,
      COL4=GPIO34, COL5=GPIO33, COL6=GPIO47, COL7=GPIO26,
      COL8=GPIO21, COL9=GPIO18, COL10=GPIO17,
      COL11=GPIO16, COL12=GPIO15
```

---

## 3. I²C bus

```text
SCL = GPIO10
SDA = GPIO11
```

One bus, shared by the three onboard devices and the Qwiic connector, which
also share one address space. The board carries 5.1 kΩ pull-ups, so internal
pull-ups are not needed.

### Onboard I²C devices

| Device | Function | Address | Extra signal |
|---|---|---:|---|
| TMP103 | Temperature sensor | `0x70` | none |
| SC7A20 | Accelerometer | `0x19` | `INT1` to GPIO12 |
| NS2009 | Resistive-touch controller | `0x48` | IRQ to GPIO13 |

### Qwiic connector J4

| J4 pin | Signal |
|---:|---|
| 1 | `I2C_SCL` |
| 2 | `I2C_SDA` |
| 3 | `+3V3` |
| 4 | `GND` |

---

## 4. Temperature sensor: TMP103

```text
Address: 0x70
```

The address identifies the part as a TMP103A.

---

## 5. Accelerometer: SC7A20

```text
Address:   0x19
Interrupt: INT1 -> GPIO12
```

`INT2` is not connected.

---

## 6. Resistive touch: NS2009

```text
Address: 0x48
IRQ:     GPIO13
```

The NS2009 reads the panel's four resistive-touch electrodes, `TP_XL`,
`TP_YU`, `TP_XR` and `TP_YD`, which also appear on display connector J2.

---

## 7. Display interface

```text
SPI clock:     GPIO5  -> display `SPI_SCL`
SPI MOSI:      GPIO8  -> display `SPI_SDA`
SPI MISO:      GPIO9  -> display `SPI_SDO`
Chip select:   GPIO7
Data/command:  GPIO4
Reset:         GPIO6
Backlight:     GPIO3
```

> Note the naming: the display connector calls its SPI signals `SPI_SCL`,
> `SPI_SDA` and `SPI_SDO`. They are **SPI**, not the board's I²C `SCL`/`SDA`.

The backlight is **active low**, and its control node has a 100 kΩ pull-up.
An undriven GPIO3 therefore leaves the backlight off, which is what a board
shows before firmware opens the display, and again if that firmware stops.

Panel controller and geometry are in section 15.

### Display connector J2 pinout

| J2 pin | Signal |
|---:|---|
| 18 | GND |
| 17 | `RST` |
| 16 | `SPI_SCL` |
| 15 | `D/C` |
| 14 | `SPI_CS` |
| 13 | `SPI_SDA` |
| 12 | `SPI_SDO` |
| 11 | GND |
| 10 | +3V3 |
| 9 | `V_BL` |
| 8 | `BL_K1` |
| 7 | `BL_K2` |
| 6 | `BL_K3` |
| 5 | `BL_K4` |
| 4 | `TP_XL` |
| 3 | `TP_YU` |
| 2 | `TP_XR` |
| 1 | `TP_YD` |

---

## 8. Addressable RGB LEDs

Four **SK6812MINI-E**, daisy-chained `DOUT -> DIN`:

```text
GPIO14 / NEOPIXEL -> 100 Ω -> D8 -> D9 -> D10 -> D11
```

The LEDs run from +5V while the data line is driven at 3.3 V, with no level
shifter in between. It works on this board; the 100 Ω series resistor is part
of why.

A working SPI configuration is in section 15.

---

## 9. Keyboard matrix

6 rows by 13 columns, `ROW0..ROW5` and `COL0..COL12`.

| Matrix row | GPIO |   | Matrix column | GPIO |
|---|---:|---|---|---:|
| ROW0 | 38 |   | COL0 | 37 |
| ROW1 | 39 |   | COL1 | 36 |
| ROW2 | 40 |   | COL2 | 35 |
| ROW3 | 41 |   | COL3 | 48 |
| ROW4 | 42 |   | COL4 | 34 |
| ROW5 | 45 |   | COL5 | 33 |
|  |  |   | COL6 | 47 |
|  |  |   | COL7 | 26 or 46, disputed |
|  |  |   | COL8 | 21 |
|  |  |   | COL9 | 18 |
|  |  |   | COL10 | 17 |
|  |  |   | COL11 | 16 |
|  |  |   | COL12 | 15 |

**COL7 is unresolved.** This document reads GPIO26 from the schematic and
shows no net on GPIO46. The badge firmware uses GPIO46 and notes it as a
strapping pin. Both cannot be right, and GPIO26 is a flash/PSRAM pin on the
ESP32-S3, so the firmware is the likelier of the two.

ROW5 (GPIO45) is a strapping pin that boots pulled down, so a scanner driving
rows open-drain has to enable its pull-up explicitly.

There are no per-key diodes, so the matrix ghosts: three keys at three corners
of a rectangle read as four.

The schematic carries the physical key legends, but several top-row and edge
keys are icons or unlabeled. Keep the electrical `(row, column)` scan separate
from the logical keymap so the keymap can be corrected on its own.

---

## 10. Infrared TX/RX

```text
GPIO43 / UART_TX -> IR_TX -> IR LED
GPIO44 / UART_RX <- IR_RX <- phototransistor
```

The GPIO sinks LED current, so the transmitter is driven low to emit. The
receive node idles high and is pulled toward GND when the phototransistor is
lit.

A standard UART can in principle drive this, but RX suffers corrupted reads in
sunlight and bright rooms, so the enclosure matters for reliable links.

---

## 11. USB

Native ESP32-S3 USB on GPIO19 (`D-`) and GPIO20 (`D+`), with no USB-to-UART
bridge on the board.

**Firmware implication:** the console and flashing go over native USB, and the
badge enumerates as `/dev/ttyACM*` rather than `/dev/ttyUSB*`. The dedicated
UART pins GPIO43 and GPIO44 are taken by the IR circuit.

---

## 12. BOOT and ENABLE/RESET buttons

Both buttons pull their line to GND against a pull-up.

- **BOOT** (SW5) pulls GPIO0 low, so GPIO0 reads low while it is held.
- **ENABLE/RESET** (SW3) pulls the ESP32 `EN` line low and resets the module.

---

## 13. Battery and USB voltage sensing

Both rails reach the ADC through an even divider, so firmware doubles what it
reads:

```text
V(GPIO1) = V(BATT) / 2     ADC1_CH0
V(GPIO2) = V(VBUS) / 2     ADC1_CH1
```

---

## 14. Copy/paste constants for firmware

```elixir
defmodule Badge.Hardware do
  # I2C
  @i2c_scl 10
  @i2c_sda 11
  @tmp103_address 0x70
  @sc7a20_address 0x19
  @ns2009_address 0x48
  @accel_irq 12
  @touch_irq 13

  # Display
  @display_backlight 3
  @display_dc 4
  @display_spi_clk 5
  @display_reset 6
  @display_spi_cs 7
  @display_spi_mosi 8
  @display_spi_miso 9

  # Addressable RGB LEDs
  @neopixel_data 14
  @neopixel_count 4

  # Native USB
  @usb_dm 19
  @usb_dp 20

  # IR / UART
  @ir_tx 43
  @ir_rx 44

  # Analog sensing
  @battery_sense 1
  @vbus_sense 2

  # Keyboard
  @keyboard_rows [38, 39, 40, 41, 42, 45]
  @keyboard_cols [37, 36, 35, 48, 34, 33, 47, 46, 21, 18, 17, 16, 15]
end
```

---

## 15. Known-good configuration

### Display

A 240x320 ST7789 panel, mounted landscape, so the driver is given the rotated
geometry:

```elixir
compatible: "sitronix,st7789",
init_seq_type: "alt_gamma_2",
enable_tft_invon: true,
width: 320,
height: 240,
rotation: 3,
reset: 6, dc: 4, cs: 7,
backlight: 3, backlight_active: :low, backlight_enabled: true
```

The SPI bus is `"spi2"` with `sclk: 5`, `mosi: 8`, `miso: 9`.

### RGB LEDs

Driven as an SPI waveform rather than bit banged. The chain has no clock line,
so SCLK is -1, and no chip select, so CS is -1:

```elixir
peripheral: "spi3", sclk: -1, mosi: 14,
clock_speed_hz: 3_200_000, mode: 0, cs: -1,
address_len_bits: 0, command_len_bits: 0
```

At 3.2 MHz one SPI bit is about 312 ns, so each LED bit is sent as four SPI
bits, `0b1000` for a zero and `0b1100` for a one. Colour order is GRB.

---
