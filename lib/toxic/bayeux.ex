defmodule Toxic.Bayeux do
  @moduledoc false

  defimpl Poison.Encoder, for: Tuple do
  def encode(tuple, options) do
    tuple
    |> Tuple.to_list
    |> Poison.encode!
  end
end

  require Logger

  def get_oauth_client() do
    username = "josh+salesforce2@peatfirestudios.com"
    password = "fX8$r4J16GyymF!k"
    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.Password,
        client_id:
          "3MVG9fTLmJ60pJ5LiXLd.IzjCRJdgGvKKWWNpTL3A_swdGE7JZLH8L9mxhK2lr17_BjEp9E5oxHkxqlxciWUz",
        client_secret: "5312996714384606617",
        username: username,
        password: password,
        site: "https://eu16.salesforce.com/cometd/44.0/",
        authorize_url: "https://login.salesforce.com/services/oauth2/authorize",
        token_url: "https://login.salesforce.com/services/oauth2/token"
      )

    client = OAuth2.Client.put_header(client, "accept", "application/json")

    client =
      OAuth2.Client.get_token!(
        client,
        username: username,
        password: password
      )

    {:ok, client}
  end

  def refresh_oauth_client(client) do
    refresh_token = client.token.refresh_token

    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.Refresh,
        client_id:
          "3MVG9fTLmJ60pJ5LiXLd.IzjCRJdgGvKKWWNpTL3A_swdGE7JZLH8L9mxhK2lr17_BjEp9E5oxHkxqlxciWUz",
        client_secret: "5312996714384606617",
        site: "https://eu16.salesforce.com/cometd/44.0/",
        params: %{
          "refresh_token" => refresh_token
        }
      )

    client = OAuth2.Client.get_token!(client)
    {:ok, client}
  end

  def filter_events(response) do
    Enum.filter(response, fn x -> match?(Toxic.Bayeux.Event, x) end)
  end

  def filter_info(response) do
    Enum.filter(response, fn x -> match?(Toxic.Bayeux.Connect, x) end)
  end

  def connect(client, initial \\ true, connect_timeout \\ 110000) do
    connect_request_payload = %{
      # MUST
      channel: "/meta/connect",
      connectionType: "long-polling",
      clientId: client.clientId
    }

    Logger.debug("Connect Payload: #{Poison.encode!(connect_request_payload)}")

    {response, client} = send_message(client, connect_request_payload, connect_timeout)

    parsed_response = Poison.decode!(response.body, as: [%Toxic.Bayeux.Event{data: %Toxic.Bayeux.Event.Data{event: %Toxic.Bayeux.Event.Data.Event{}, sobject: %Toxic.Bayeux.Event.Data.SObject{}}}, %Toxic.Bayeux.Connect{}])

    Logger.debug("Response Body: #{response.body}")

    events = filter_events(parsed_response)
    info = filter_info(parsed_response)

    queue_process = Process.get(:inbound_queue)

    Enum.map(events, fn (event) -> queue_process.push(event) end)

    connect(client, false, connect_timeout)
  end

  def update_client_cookies(client, http_response) do
    cookies = Enum.filter(http_response.headers, fn {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i) end)
    Logger.debug("Cookies (pre-update): #{Poison.encode!(cookies)}")
    cookies = Enum.map(
      cookies,
      fn(value) ->
        elem(value, 1)
        |> String.split(";")
        |> List.first
      end
    )
    Logger.debug("Cookies (post-update): #{Poison.encode!(cookies)}")

    client = Map.update(client, :cookies, cookies, fn(_) -> cookies end)

    {:ok, client }
  end

  def send_message(client, payload, timeout \\ 3000) do
    client =
      Map.update(
        client,
        :message_id,
        1,
        fn value -> value + 1 end
      )

    payload =
      Map.update(
        payload,
        :id,
        client.message_id,
        fn _ ->
          client.message_id
        end
      )

    payload = Poison.encode!([payload])
    Logger.debug("Client: #{Poison.encode!(client)}")
    Logger.debug("Payload: #{payload}")
    access_token = client.token.access_token

    headers = [
      {"Authorization", "OAuth #{access_token}"},
      {"Content-Type", "application/json"}
    ]


    response = case HTTPoison.post(
      client.site,
      payload,
      headers,
      [
        hackney: [
          cookie: Map.get(client, :cookies, [])
        ],
        recv_timeout: timeout
      ]
    ) do
      {:ok, response} ->
        response
      {:error, %HTTPoison.Error{id: _, reason: :timeout}} ->
        Logger.info("Request timed out")
        %{body: "[#{Poison.encode!(payload)}]"}
    end


    Logger.debug("Response: #{Poison.encode!(response)}")

    { response, client }
  end

  #
  #  '''
  #    Copyright (c) 2016, Salesforce.org
  #    All rights reserved.
  #    Redistribution and use in source and binary forms, with or without
  #    modification, are permitted provided that the following conditions are met:
  #    * Redistributions of source code must retain the above copyright
  #      notice, this list of conditions and the following disclaimer.
  #    * Redistributions in binary form must reproduce the above copyright
  #      notice, this list of conditions and the following disclaimer in the
  #      documentation and/or other materials provided with the distribution.
  #    * Neither the name of Salesforce.org nor the names of
  #      its contributors may be used to endorse or promote products derived
  #      from this software without specific prior written permission.
  #    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  #    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  #    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
  #    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
  #    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
  #    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  #    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  #    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  #    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  #    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  #    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  #    POSSIBILITY OF SUCH DAMAGE.
  # '''
  #
  # import gevent.monkey
  # gevent.monkey.patch_all()
  #
  # import simplejson as json
  # import gevent
  # import gevent.queue
  # import requests
  # import requests.exceptions
  # from datetime import datetime
  # from copy import deepcopy
  #
  # import logging
  # LOG = logging.getLogger('python_bayeux')
  #
  ## See https://docs.cometd.org/current/reference/#_bayeux for bayeux reference

  def disconnect(client) do
    disconnect_payload = %{
      # MUST
      channel: '/meta/disconnect',
      clientId: None,
      # MAY
      id: None
    }

    { disconnect_response, client } =
      send_message(
        client,
        disconnect_payload
      )

    #        self.disconnect_complete = True
    {:ok, client}
  end

  def handshake(client) do
    handshake_payload = %{
      channel: "/meta/handshake",
      supportedConnectionTypes: ["long-polling"],
      version: "1.0",
      minimumVersion: "1.0"
    }

    {handshake_response, client} = send_message(client, handshake_payload)

    {:ok, client } = update_client_cookies(client, handshake_response)

    [parsed_response] = Poison.decode!(handshake_response.body, as: [%Toxic.Bayeux.Handshake{}])

    Logger.debug("Response Body: #{handshake_response.body}")

    client =
      Map.update(client, :clientId, parsed_response.clientId, fn _ -> parsed_response.clientId end)

    {:ok, client}
  end

  def subscribe(client, channel) do
    subscribe_payload = %{
      channel: "/meta/subscribe",
      clientId: client.clientId,
      subscription: "/topic/#{channel}"
    }

    { handshake_response, client } = send_message(client, subscribe_payload)

    [parsed_response] = Poison.decode!(handshake_response.body, as: [%Toxic.Bayeux.Subscribe{}])

    Logger.debug("Response Body: #{handshake_response.body}")

    {:ok, client}
  end

  def add_to_publish_queue(channel, payload) do
    Logger.info("enqueueing publication of #{payload} to channel #{channel}")

    GenServer.cast(
      :outbound_queue,
      %{
        channel: channel,
        payload: payload
      }
    )
  end

  def publish_task do
  end

  def add_to_unsub_queue(channel) do
    Logger.info("enqueueing unsubscription for channel #{channel}")

    GenServer.cast(
      :outbound_queue,
      %{
        channel: "/meta/unsubscribe",
        subscription: channel
      }
    )
  end

  def unsub_task do
  end
end
