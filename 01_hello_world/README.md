# Exercise 1: Console Hello World

Build, flash and see console output from an AtomVM application.

## Install AtomVM on the badge (once)

```sh
mix deps.get
mix atomvm.esp32.install --image AtomVM-esp32s3-atomgl-ipv6-libsodium-psram-elixir-nightly-0.7
```

That nightly has AtomGL compiled in, which a later exercise needs. It erases the
flash and asks for confirmation first.

## The application

`lib/hello_world.ex` holds the whole application. `HelloWorld.start/0` is the
entry point, named in `mix.exs`:

```elixir
atomvm: [
  start: HelloWorld
]
```

`start/0` must never return: when it does, AtomVM stops the application and the
board goes to sleep. Keep it alive with a loop.

## Flash and monitor

```sh
mix atomvm.esp32.flash                  # builds hello_world.avm, writes it to main.avm
mix atomvm.esp32.monitor --timeout 10   # console for 10 seconds, then exits
```

```text
I (xxx) AtomVM: Starting Elixir.HelloWorld.beam...
---
Hello from AtomVM!
Still alive, 0 seconds
```

## Good to know

* Badge not detected: hold **BOOT**, tap **RESET**, release **BOOT**, retry.
* Several boards connected: add `--port /dev/ttyACM0`.
* `mix atomvm.esp32.monitor` without `--timeout` runs until Ctrl+C, pressed twice.
* The `mix atomvm.*` tasks bring their own `esptool` through `:pythonx`, so
  nothing has to be installed system-wide.
