defmodule Power do
  @battery_pin 1
  @vbus_pin 2

  # Both rails reach the ADC through an even divider, so the pin sees half.
  @divider 2

  # Averaged per reading. The ADC is noisy and a battery moves slowly.
  @samples 64

  @interval 2_000

  # Working range of the cell, in millivolts.
  @empty 3300
  @full 4200

  # VBUS above this means USB is supplying power.
  @usb_present 4000

  def start do
    {:ok, unit} = Esp.ADC.init()
    {:ok, battery} = Esp.ADC.acquire(@battery_pin, unit, :bit_max, :db_12)
    {:ok, vbus} = Esp.ADC.acquire(@vbus_pin, unit, :bit_max, :db_12)

    loop(unit, battery, vbus)
  end

  defp loop(unit, battery, vbus) do
    battery_mv = read_mv(unit, battery)
    vbus_mv = read_mv(unit, vbus)

    IO.puts(
      "battery #{battery_mv} mV (#{percent(battery_mv)}%)   " <>
        "vbus #{vbus_mv} mV   usb #{usb?(vbus_mv)}"
    )

    Process.sleep(@interval)
    loop(unit, battery, vbus)
  end

  # sample/3 gives the raw count and the calibrated voltage at the pin, which
  # is half the voltage on the rail.
  defp read_mv(unit, channel) do
    {:ok, {_raw, mv}} = Esp.ADC.sample(channel, unit, [:raw, :voltage, {:samples, @samples}])

    mv * @divider
  end

  defp percent(mv) when mv <= @empty, do: 0
  defp percent(mv) when mv >= @full, do: 100
  defp percent(mv), do: div((mv - @empty) * 100, @full - @empty)

  defp usb?(vbus_mv), do: vbus_mv >= @usb_present
end
