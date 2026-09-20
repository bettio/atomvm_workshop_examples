defmodule TMP103 do
  @moduledoc """
  Minimal driver for the TI TMP103 temperature sensor on the badge.

  Four registers selected by a pointer byte; 0x00 is the temperature, one byte,
  1 LSB = 1 °C, negative values in two's complement.
  """

  @address 0x70
  @temperature_register 0x00

  def read(i2c) do
    {:ok, <<temperature::signed-integer-8>>} =
      I2C.read_bytes(i2c, @address, @temperature_register, 1)

    temperature
  end
end
