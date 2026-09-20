defmodule Display do
  # Panel: ST7789 over SPI, mounted landscape, so 320x240 with rotation 3.
  @width 320
  @height 240

  @spi_peripheral "spi2"
  @spi_sclk 5
  @spi_mosi 8
  @spi_miso 9

  @display_cs 7
  @display_dc 4
  @display_reset 6
  @display_backlight 3

  @i2c_scl 10
  @i2c_sda 11

  def start do
    spi = open_spi()
    display = :erlang.open_port({:spawn, "display"}, display_opts(spi))
    i2c = I2C.open(scl: @i2c_scl, sda: @i2c_sda, clock_speed_hz: 100_000)

    {:ok, scene} =
      TemperatureScene.start_link([width: @width, height: @height],
        display_server: {:port, display}
      )

    loop(i2c, scene)
  end

  # The scene owns the screen: the loop only tells it the new value.
  defp loop(i2c, scene) do
    send(scene, {:temperature, TMP103.read(i2c)})

    Process.sleep(1_000)
    loop(i2c, scene)
  end

  # AtomGL adds its own SPI device, so device_config stays empty here.
  defp open_spi do
    :spi.open(%{
      bus_config: %{
        peripheral: @spi_peripheral,
        sclk: @spi_sclk,
        mosi: @spi_mosi,
        miso: @spi_miso
      },
      device_config: %{}
    })
  end

  defp display_opts(spi) do
    [
      compatible: "sitronix,st7789",
      init_seq_type: "alt_gamma_2",
      enable_tft_invon: true,
      width: @width,
      height: @height,
      rotation: 3,
      reset: @display_reset,
      dc: @display_dc,
      cs: @display_cs,
      backlight: @display_backlight,
      backlight_active: :low,
      backlight_enabled: true,
      spi_host: spi
    ]
  end
end
