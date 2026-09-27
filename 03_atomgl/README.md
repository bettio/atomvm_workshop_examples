# Exercise 3: Show the temperature on the display

Put the value from exercise 2 on the badge screen with AtomGL.

Assumes AtomVM is already installed on the badge, see exercise 1. The VM must
have AtomGL compiled in, which the image installed there does.

## The application

`lib/display.ex` opens the hardware and runs the loop,
`lib/temperature_scene.ex` draws, and `lib/tmp103.ex` is the sensor driver from
exercise 2. `Display.start/0` is the entry point, named in `mix.exs`:

```elixir
atomvm: [
  start: Display
]
```

## The display

Two steps: open the SPI bus, then open the display port on top of it. AtomGL
adds its own SPI device, so `device_config` stays empty.

```elixir
spi = :spi.open(%{
  bus_config: %{peripheral: "spi2", sclk: 5, mosi: 8, miso: 9},
  device_config: %{}
})

display = :erlang.open_port({:spawn, "display"}, [
  compatible: "sitronix,st7789",
  init_seq_type: "alt_gamma_2",
  enable_tft_invon: true,
  width: 320, height: 240, rotation: 3,
  reset: 6, dc: 4, cs: 7,
  backlight: 3, backlight_active: :low, backlight_enabled: true,
  spi_host: spi
])
```

The panel is 240x320 natively. The badge mounts it landscape, so the driver is
given 320x240 and `rotation: 3`. These values are not guessable from the
schematic, they come from the badge firmware.

## The scene

AtomGL is declarative. You never draw: you hand it a display list and it
replaces everything on screen. The first item is on top, the last is drawn
first, so the background rectangle goes at the end of the list.

`avm_scene` wraps that in a `gen_server`. Any callback that returns
`[{:push, items}]` updates the panel:

```elixir
def handle_info({:temperature, temperature}, state) do
  state = %{state | temperature: temperature}
  {:noreply, state, [{:push, render(state)}]}
end
```

The loop never touches the screen, it only sends the scene a new value.

## Flash and monitor

```sh
mix atomvm.esp32.flash
mix atomvm.esp32.monitor --timeout 10
```
