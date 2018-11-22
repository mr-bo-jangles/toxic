defmodule Toxic.Bayeux.Connect do
  @moduledoc false
  defstruct [
    :channel,
    :clientId,
    :ext,
    :id,
    :successful,
    :advice,
    :error
  ]
end
