# Exercise 6: Read the keyboard with interrupts

Turn the badge's 6 x 13 key matrix into press and release events, without
polling it when nobody is typing.

Assumes AtomVM is already installed on the badge, see exercise 1.

## The application

`lib/keyboard.ex` is a GenServer that owns the matrix, `lib/keymap.ex` says
what each position means.
`Keyboard.start/0` is the entry point, named in `mix.exs`:

```elixir
atomvm: [
  start: Keyboard
]
```

## How a matrix works

78 keys on 19 pins, because each key sits where one row crosses one column.

Columns are inputs held high by internal pull-ups. Drive one row low and any
key closed in that row pulls its own column low with it. Read all thirteen
columns, move to the next row, repeat:

```elixir
GPIO.digital_write(row_pin, :low)
# every column reading :low is a key held down in this row
GPIO.digital_write(row_pin, :high)
```

Rows are **open drain**, so writing `:high` releases the line rather than
driving it. That matters because the badge has no diodes: if two rows were
driven hard and a key shorted them together, they would fight. ROW5 (GPIO45)
boots with an internal pull-down, so its pull-up has to be set explicitly.

## Waking on a key

Scanning 50 times a second to learn that nobody is typing is a waste. The
badge can tell us instead.

Hold **every** row low at once and the matrix becomes one big button: closing
any key pulls its own column down. Arm a falling-edge interrupt on all
thirteen columns and the hardware sends the badge a message:

```elixir
GPIO.set_int(gpio, pin, :falling)
```

`{:gpio_interrupt, pin}` then arrives in the mailbox of whichever process
armed it, which is an ordinary Erlang message. So the keyboard is a GenServer
and the interrupt is just another `handle_info`:

```elixir
def handle_info({:gpio_interrupt, _pin}, %{pressed: []} = state) do
  disarm(state.gpio)
  {:noreply, scan_and_report(state)}
end
```

An idle GenServer costs nothing. There is no timer and no polling loop.

The server has two states, and they are told apart by the state itself:

```text
pressed == []   idle: rows all low, interrupts armed, waiting for a message
pressed != []   active: interrupts off, a :scan scheduled every 20 ms
```

The interrupt says *something* was pressed, never what. Finding out means
scanning, and scanning drives rows one at a time, which would retrigger the
interrupts we just armed. So the handler disarms them first, and once every
key is released the server arms them again and goes back to idle.

That also explains the second clause. An interrupt arriving while keys are
already held is an echo of our own scanning, and pattern matching on `pressed`
throws it away:

```elixir
def handle_info({:gpio_interrupt, _pin}, state), do: {:noreply, state}
```

Events are the difference between two scans, so a held key is reported once:

```elixir
Enum.each(pressed -- was_pressed, fn key -> report("pressed ", key) end)
Enum.each(was_pressed -- pressed, fn key -> report("released", key) end)
```

Scanning every 20 ms also handles contact bounce, which settles well inside
one interval.

## Flash and monitor

```sh
mix atomvm.esp32.flash
mix atomvm.esp32.monitor --timeout 20
```

```text
Press a key.
pressed   row 2 col 1  Q
released  row 2 col 1  Q
```
