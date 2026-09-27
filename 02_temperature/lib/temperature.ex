defmodule Temperature do
  # Badge I2C bus: shared by the TMP103, the accelerometer, the touch
  # controller and the Qwiic connector.
  @i2c_scl 10
  @i2c_sda 11

  def start do
    i2c = I2C.open(scl: @i2c_scl, sda: @i2c_sda, clock_speed_hz: 100_000)

    loop(i2c)
  end

  defp loop(i2c) do
    temperature = TMP103.read(i2c)
    IO.puts("Temperature: #{temperature} °C")

    Process.sleep(1_000)
    loop(i2c)
  end
end
