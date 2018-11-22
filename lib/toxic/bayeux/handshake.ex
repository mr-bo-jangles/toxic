defmodule Toxic.Bayeux.Handshake do
  @moduledoc false
  defstruct [
    :channel,
    :clientId,
    :ext,
    :id,
    :minimumVersion,
    :successful,
    :supportedConnectionTypes,
    :version
  ]
end
