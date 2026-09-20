# Exercise 5: Rainbows on the RGB LEDs

Animate the badge's four SK6812MINI-E LEDs, using the SPI peripheral as a
waveform generator.

Assumes AtomVM is already installed on the badge, see exercise 1.

## The application

`lib/rainbow.ex` computes colours and runs the loop, `lib/sk6812.ex` turns them
into a bitstream. `Rainbow.start/0` is the entry point, named in `mix.exs`:

```elixir
atomvm: [
  start: Rainbow
]
```

## Why SPI

These LEDs have no clock line. Each bit is a pulse of fixed width whose high
part carries the value: short is a zero, long is a one, about 1.25 us per bit.
Miss the timing and the chain shows nonsense.

Elixir cannot hold that timing, and should not try. Instead the SPI peripheral
clocks out a prepared waveform in hardware. At 3.2 MHz one SPI bit lasts about
312 ns, so each LED bit is sent as four SPI bits:

```text
LED bit 0  ->  0b1000
LED bit 1  ->  0b1100
```

One colour byte becomes four SPI bytes, one pixel costs twelve, and a run of
zero bytes at the end holds the line low long enough to latch the frame.

```elixir
spi = :spi.open(%{
  bus_config: %{peripheral: "spi3", sclk: -1, mosi: 14},
  device_config: %{pixels: %{clock_speed_hz: 3_200_000, mode: 0, cs: -1,
                             address_len_bits: 0, command_len_bits: 0}}
})

:ok = :spi.write(spi, :pixels, %{write_data: frame <> latch})
```

`sclk: -1` and `cs: -1` because the chain uses neither. Only the data line on
GPIO14 matters.

## The rainbow

The four LEDs sit an equal distance apart on the colour wheel, and the wheel
turns three degrees every 20 ms, so a full revolution takes 2.4 seconds.

Colours are computed in integer HSV. Floats work on AtomVM, but there is no
reason to spend them on this.

## Flash and monitor

```sh
mix atomvm.esp32.flash
mix atomvm.esp32.monitor --timeout 10
```

Nothing is printed. The LEDs are the output.
