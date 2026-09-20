defmodule TemperatureScene do
  # AtomGL's built-in font is the Linux 8x16 VGA font, indexed by raw byte in
  # CP437 layout. Byte 0xF8 is the degree sign; UTF-8 would draw two wrong
  # glyphs instead.
  @degree <<0xF8>>

  @background 0x000000
  @label 0x808080
  @value 0xFFFFFF

  def start_link(args, opts) do
    :avm_scene.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %{
      width: Keyword.fetch!(args, :width),
      height: Keyword.fetch!(args, :height),
      temperature: nil
    }

    {:ok, state}
  end

  # Returning [{:push, items}] is what sends the display list to the panel.
  def handle_info({:temperature, temperature}, state) do
    state = %{state | temperature: temperature}

    {:noreply, state, [{:push, render(state)}]}
  end

  # The first item is on top, the last is drawn first: the background rectangle
  # goes at the end.
  defp render(state) do
    [
      {:text, 20, 100, :default16px, @value, :transparent, value(state.temperature)},
      {:text, 20, 70, :default16px, @label, :transparent, "Temperature"},
      {:rect, 0, 0, state.width, state.height, @background}
    ]
  end

  defp value(nil), do: "--"
  defp value(temperature), do: "#{temperature} " <> @degree <> "C"
end
