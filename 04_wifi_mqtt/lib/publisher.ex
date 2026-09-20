defmodule Publisher do
  # Everything worth changing lives in config/config.exs. compile_env! reads it
  # while compiling on the laptop, so the badge never sees Application at all.
  @ssid Application.compile_env!(:publisher, [:wifi, :ssid])
  @psk Application.compile_env!(:publisher, [:wifi, :psk])
  @broker Application.compile_env!(:publisher, [:mqtt, :host])
  @broker_port Application.compile_env!(:publisher, [:mqtt, :port])
  @topic_prefix Application.compile_env!(:publisher, :topic_prefix)

  @interval 5_000

  @i2c_scl 10
  @i2c_sda 11

  def start do
    IO.puts("Connecting to #{@ssid}...")
    {:ok, address} = Wifi.connect(@ssid, @psk)
    IO.puts("Connected, IP #{address}")

    topic = "#{@topic_prefix}/#{badge_id()}/temperature"
    client = connect_mqtt()
    i2c = I2C.open(scl: @i2c_scl, sda: @i2c_sda, clock_speed_hz: 100_000)

    IO.puts("Publishing to #{topic}")
    loop(i2c, client, topic)
  end

  defp loop(i2c, client, topic) do
    temperature = TMP103.read(i2c)

    :ok = :amqtt_client.publish(client, topic, "#{temperature}", 0)
    IO.puts("#{topic} #{temperature}")

    Process.sleep(@interval)
    loop(i2c, client, topic)
  end

  # connect/1 returns as soon as the CONNECT packet is on its way. The broker
  # accepting it arrives later, as a message to whoever called connect/1.
  defp connect_mqtt do
    {:ok, client} =
      :amqtt_client.connect(%{
        host: @broker,
        port: @broker_port,
        client_id: "badge-" <> badge_id()
      })

    receive do
      {:mqtt, ^client, :connack, _info} ->
        IO.puts("MQTT connected to #{@broker}")
        client
    after
      15_000 ->
        IO.puts("No answer from #{@broker}, is it reachable from this network?")
        exit(:mqtt_timeout)
    end
  end

  # Last three bytes of the factory MAC, so every badge gets its own topic
  # without anyone having to pick a number.
  defp badge_id do
    {:ok, <<_::binary-size(3), tail::binary-size(3)>>} = :esp.get_default_mac()

    Base.encode16(tail, case: :lower)
  end
end
