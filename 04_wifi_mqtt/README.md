# Exercise 4: Publish the temperature over MQTT

Join a Wi-Fi network, connect to an MQTT broker, publish the reading from
exercise 2.

Assumes AtomVM is already installed on the badge, see exercise 1.

## Before flashing

Everything worth changing is in `config/config.exs`:

```elixir
config :publisher, :wifi,
  ssid: "YOUR_WIFI",
  psk: "YOUR_PASSWORD"

config :publisher, :mqtt,
  host: ~c"test.mosquitto.org",
  port: 1883
```

`Application.compile_env!/2` reads those while compiling on the laptop, so the
badge never runs `Application` at all. To keep your own credentials out of git,
put the same `config :publisher, ...` lines in `config/config_local.exs`, which
is gitignored and overrides the committed file.

## The application

`lib/publisher.ex` orchestrates and publishes, `lib/wifi.ex` wraps the network
API, `lib/tmp103.ex` is the sensor driver from exercise 2. `Publisher.start/0`
is the entry point, named in `mix.exs`:

```elixir
atomvm: [
  start: Publisher
]
```

## Wi-Fi

Associating with an access point and getting an address from DHCP are two
different things. `wait_for_sta/2` waits for both:

```elixir
:network.wait_for_sta([ssid: ssid, psk: psk, dhcp_hostname: "avm-badge"], 30_000)
```

It answers `{:ok, {address, netmask, gateway}}`, or `{:error, :timeout}` and
`{:error, :disconnected}` when it does not work. A wrong passphrase looks like
`:disconnected`.

## MQTT

`:amqtt_client` is an MQTT 3.1.1 client written in plain Erlang, packed into
the `.avm` like any other module.

Connecting is asynchronous. `connect/1` returns as soon as the CONNECT packet
is on its way, and the broker's answer arrives later as a message to whoever
called it:

```elixir
{:ok, client} = :amqtt_client.connect(%{host: broker, port: 1883, client_id: id})

receive do
  {:mqtt, ^client, :connack, _info} -> client
end
```

Publishing at QoS 0 is fire and forget:

```elixir
:ok = :amqtt_client.publish(client, topic, "24", 0)
```

## The topic

Every badge publishes to its own topic, built from the last three bytes of the
factory MAC address, so nobody has to pick a number:

```text
goatmire/badge/a1b2c3/temperature
```

The badge prints its topic at startup. Watch it from a laptop with:

```sh
mosquitto_sub -h test.mosquitto.org -t 'goatmire/badge/+/temperature' -v
```

## Flash and monitor

```sh
mix atomvm.esp32.flash
mix atomvm.esp32.monitor --timeout 20
```

```text
Connecting to YOUR_WIFI...
Connected, IP 192.168.1.42
MQTT connected to test.mosquitto.org
Publishing to goatmire/badge/a1b2c3/temperature
goatmire/badge/a1b2c3/temperature 28
```
