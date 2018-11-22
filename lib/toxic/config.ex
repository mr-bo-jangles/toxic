defmodule Toxic.Config do
  @moduledoc "Acts as the configuration store for the service. Holds the details for each api translation"
  use Agent

  @enforce_keys [:origin_endpoint, :dest_endpoint]
  defstruct origin_endpoint: "",
            origin_username: "",
            origin_password: "",
            origin_topic: "",
            dest_endpoint: "",
            dest_username: "",
            dest_password: ""

  def start_link(_) do
    Agent.start_link(fn -> MapSet.new() end, name: __MODULE__)
  end

  @doc "Adds a mapping of origin to destination"
  def put_mapping(
        origin_endpoint,
        origin_username,
        origin_password,
        origin_topic,
        dest_endpoint,
        dest_username,
        dest_password
      ) do
    item = %Toxic.Config{
      origin_endpoint: origin_endpoint,
      origin_username: origin_username,
      origin_password: origin_password,
      origin_topic: origin_topic,
      dest_endpoint: dest_endpoint,
      dest_username: dest_username,
      dest_password: dest_password
    }

    Agent.update(__MODULE__, &MapSet.put(&1, item))
  end

  def get_mappings do
    Agent.get(__MODULE__, & &1)
  end
end
