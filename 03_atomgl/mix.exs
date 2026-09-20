defmodule Display.MixProject do
  use Mix.Project

  def project do
    [
      app: :display,
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps(),
      atomvm: [
        start: Display
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:atomvm, "~> 0.7.0-alpha.1", runtime: false},
      # The only dependency that is packed into the .avm: it wraps the AtomGL
      # display port in a gen_server that pushes a new display list whenever a
      # callback returns one. Taken from git, because the published Hex package
      # ships no build config.
      {:avm_scene, github: "atomvm/avm_scene"},
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
