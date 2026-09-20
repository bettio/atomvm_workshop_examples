defmodule Rainbow.MixProject do
  use Mix.Project

  def project do
    [
      app: :rainbow,
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps(),
      atomvm: [
        start: Rainbow
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:atomvm, "~> 0.7.0-alpha.1", runtime: false},
      {:exatomvm, github: "AtomVM/exatomvm", runtime: false},
      # Runs esptool in-process, which is what makes the mix atomvm.esp32.*
      # tasks pleasant to use: port detection, monitor and install all need it.
      # Everything is still possible without pythonx, as long as esptool is in
      # $PATH, but the experience is rougher.
      {:pythonx, "~> 0.4.0", runtime: false},
      # Downloads the firmware image for mix atomvm.esp32.install.
      {:req, "~> 0.5.0", runtime: false}
    ]
  end
end
