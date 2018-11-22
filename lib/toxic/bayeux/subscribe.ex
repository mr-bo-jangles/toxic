defmodule Toxic.Bayeux.Subscribe do
  @moduledoc false
  defstruct [
    :channel,
    :successful,
    :subscription,
    :error,
    :advice,
    :ext,
    :clientId,
    :id
  ]
end
