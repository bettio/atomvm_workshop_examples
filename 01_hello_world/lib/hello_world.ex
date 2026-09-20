defmodule HelloWorld do
  # AtomVM calls start/0 when the board boots.
  def start do
    IO.puts("Hello from AtomVM!")

    loop(0)
  end

  # start/0 must not return: when it does, AtomVM stops the application.
  defp loop(count) do
    Process.sleep(1_000)
    IO.puts("Still alive, #{count} seconds")

    loop(count + 1)
  end
end
