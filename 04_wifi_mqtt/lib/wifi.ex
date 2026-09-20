defmodule Wifi do
  @moduledoc """
  Association and DHCP around the AtomVM network API.
  """

  # wait_for_sta/2 returns once the badge has associated and DHCP has given it
  # an address, or with an error when neither happens in time.
  def connect(ssid, psk) do
    config = [ssid: ssid, psk: psk, dhcp_hostname: "avm-badge"]

    case :network.wait_for_sta(config, 30_000) do
      {:ok, {address, _netmask, _gateway}} -> {:ok, format(address)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp format({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
end
