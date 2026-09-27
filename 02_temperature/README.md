# Exercise 2: Read the temperature sensor

Talk to a real device over I²C and print the temperature on the console.

Assumes AtomVM is already installed on the badge, see exercise 1.

## The application

`lib/temperature.ex` is the loop, `lib/tmp103.ex` the sensor driver.
`Temperature.start/0` is the entry point, named in `mix.exs`:

```elixir
atomvm: [
  start: Temperature
]
```

## The bus

One I²C bus, shared by the TMP103, the accelerometer, the touch controller and
the Qwiic connector. Every device answers to its own address, and inside each
device registers are selected by a pointer byte: **bus → address → register**.

```elixir
i2c = I2C.open(scl: 10, sda: 11, clock_speed_hz: 100_000)
```

`clock_speed_hz` is not optional: without it the driver refuses to open the bus.

## The sensor

The badge fits a **TMP103A** at address `0x70`. Four registers, pointer `0x00`
is the temperature: a single byte, 1 LSB = 1 °C, two's complement.

```elixir
{:ok, <<temperature::signed-integer-8>>} = I2C.read_bytes(i2c, 0x70, 0x00, 1)
```

`I2C.read_bytes/4` does exactly what the datasheet asks for: address, pointer
byte, repeated start, read. `signed-integer-8` is what turns `0xFF` into `-1`.

## Flash and monitor

```sh
mix atomvm.esp32.flash
mix atomvm.esp32.monitor --timeout 10
```

```text
Temperature: 24 °C
Temperature: 24 °C
Temperature: 25 °C
```

Pinch the sensor between two fingers and the value climbs.

## Good to know

* **It reads higher than the room.** The TMP103 sits on the PCB next to the
  ESP32-S3, so it measures the board, not the air. A few degrees above ambient
  is the board heating itself.
* **The value repeats on purpose.** The TMP103 needs no setup, because out of
  reset it is already converting, but it converts at 0.25 Hz, one new sample
  every 4 seconds, while the loop prints every second. For a fresh sample every
  time, set the conversion rate to 4 Hz once, before the loop:
  `I2C.write_bytes(i2c, 0x70, 0x01, 0x42)`
