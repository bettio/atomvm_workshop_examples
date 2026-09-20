defmodule Rainbow do
  @pixel_count 4

  # Out of 255. Four LEDs at full brightness are unpleasant to look at and
  # draw a lot more current.
  @brightness 40

  # 3 degrees every 20 ms is one turn of the colour wheel every 2.4 seconds.
  @hue_step 3
  @interval 20

  def start do
    spi = SK6812.open()

    loop(spi, 0)
  end

  defp loop(spi, hue) do
    SK6812.write(spi, pixels(hue))

    Process.sleep(@interval)
    loop(spi, rem(hue + @hue_step, 360))
  end

  # The four LEDs sit an equal distance apart on the colour wheel, and the
  # whole wheel turns a little on every frame.
  defp pixels(hue) do
    for i <- 0..(@pixel_count - 1) do
      hsv_to_rgb(rem(hue + i * div(360, @pixel_count), 360), 255, @brightness)
    end
  end

  # Hue 0..359, saturation and value 0..255. Integer maths only: floats work on
  # AtomVM, but there is no reason to spend them here.
  defp hsv_to_rgb(h, s, v) do
    sector = div(h, 60)
    offset = div(rem(h, 60) * 255, 60)

    p = div(v * (255 - s), 255)
    q = div(v * (255 - div(s * offset, 255)), 255)
    t = div(v * (255 - div(s * (255 - offset), 255)), 255)

    sector_rgb(sector, v, p, q, t)
  end

  defp sector_rgb(0, v, p, _q, t), do: {v, t, p}
  defp sector_rgb(1, v, p, q, _t), do: {q, v, p}
  defp sector_rgb(2, v, p, _q, t), do: {p, v, t}
  defp sector_rgb(3, v, p, q, _t), do: {p, q, v}
  defp sector_rgb(4, v, p, _q, t), do: {t, p, v}
  defp sector_rgb(_sector, v, p, q, _t), do: {v, p, q}
end
