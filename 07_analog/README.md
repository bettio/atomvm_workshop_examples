# Exercise 7: Read the battery voltage

Measure an analog rail with the ESP32-S3 ADC.

Assumes AtomVM is already installed on the badge, see exercise 1.

## The application

`lib/power.ex` is the whole thing. `Power.start/0` is the entry point, named
in `mix.exs`:

```elixir
atomvm: [
  start: Power
]
```

## The ADC

Two rails are wired to the ADC, each through an even divider: the battery on
GPIO1 and USB VBUS on GPIO2. A channel is acquired once, then sampled:

```elixir
{:ok, unit} = Esp.ADC.init()
{:ok, battery} = Esp.ADC.acquire(1, unit, :bit_max, :db_12)

{:ok, {raw, mv}} = Esp.ADC.sample(battery, unit, [:raw, :voltage, {:samples, 64}])
```

Three things are worth knowing about that call:

* `:db_12` is the attenuation, and it is what makes the full 3.3 V range
  readable. A smaller setting measures a smaller window and clips.
* `{:samples, 64}` averages 64 reads. The ADC is noisy and a battery moves
  slowly, so there is no reason to trust a single one.
* `mv` is already calibrated millivolts, measured **at the pin**. The divider
  halves the rail, so the real voltage is `mv * 2`.

Turning volts into a percentage is a guess about the cell, not a measurement:
this one treats 3300 mV as empty and 4200 mV as full.

## Flash and monitor

```sh
mix atomvm.esp32.flash
mix atomvm.esp32.monitor --timeout 20
```

```text
battery 3960 mV (73%)   vbus 5020 mV   usb true
```

## Good to know

* **VBUS always reads about 5 V here.** You are watching the console over the
  same USB cable that supplies it. To see `usb false`, the badge has to run on
  the battery, which means no console.
