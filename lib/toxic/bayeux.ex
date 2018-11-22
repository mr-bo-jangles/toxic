defmodule Toxic.Bayeux do
  @moduledoc false

  require Logger

  def get_oauth_client() do
    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.Password,
        client_id:
          "3MVG9fTLmJ60pJ5Jh7TmZ7oIJQJg5xyDO99G27lmZj3Mr8VBpxz3QoOEJfLBZuMs41YgCIM6SeqBO0JbmrUR3",
        client_secret: "4535134718594294726",
        username: "josh+salesforce@peatfirestudios.com",
        password: "h5T&5IC0RBOA",
        site: "https://eu16.salesforce.com/cometd/44.0/",
        authorize_url: "https://login.salesforce.com/services/oauth2/authorize",
        token_url: "https://login.salesforce.com/services/oauth2/token"
      )

    client = OAuth2.Client.put_header(client, "accept", "application/json")

    client =
      OAuth2.Client.get_token!(
        client,
        username: "josh+salesforce@peatfirestudios.com",
        password: "h5T&5IC0RBOA"
      )

    {:ok, client}
  end

  def refresh_oauth_client(client) do
    refresh_token = client.token.refresh_token

    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.Refresh,
        client_id:
          "3MVG9fTLmJ60pJ5Jh7TmZ7oIJQJg5xyDO99G27lmZj3Mr8VBpxz3QoOEJfLBZuMs41YgCIM6SeqBO0JbmrUR3",
        client_secret: "4535134718594294726",
        site: "https://eu16.salesforce.com/cometd/44.0/",
        params: %{
          "refresh_token" => refresh_token
        }
      )

    client = OAuth2.Client.get_token!(client)
    {:ok, client}
  end

  def connect(client, initial \\ False, connect_timeout \\ 30) do
    connect_request_payload = %{
      # MUST
      channel: "/meta/connect",
      connectionType: "long-polling",
      clientId: client.clientId
    }

    IO.inspect(connect_request_payload)

    timeout =
      cond do
        initial == true ->
          None

        true ->
          connect_timeout
      end

    {response, client} = send_message(client = client, payload = connect_request_payload)

    [parsed_response] = Poison.decode!(response.body, as: [%Toxic.Bayeux.Connect{}])

    IO.inspect(parsed_response)

    {:ok, client}
  end

  def update_client_cookies(client, http_response) do
    cookies = Enum.filter(http_response.headers, fn {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i) end)
    IO.inspect(cookies)
    cookies = Enum.map(
      cookies,
      fn(value) ->
        elem(value, 1)
        |> String.split(";")
        |> List.first
      end
    )
    IO.inspect(cookies)

    client = Map.update(client, :cookies, cookies, fn(_) -> cookies end)

    {:ok, client }
  end

  def send_message(client, payload, timeout \\ 30) do
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

    IO.inspect(payload)
    IO.inspect(client)
    payload = Poison.encode!([payload])
    access_token = client.token.access_token

    headers = [
      {"Authorization", "OAuth #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    response = HTTPoison.post!(
      client.site,
      payload,
      headers,
      [
        hackney: [
          cookie: Map.get(client, :cookies, [])
        ]
      ]
    )

    IO.inspect(response)

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
    #        return disconnect_response
  end

  def handshake(client) do
    message_counter = 1

    handshake_payload = %{
      channel: "/meta/handshake",
      supportedConnectionTypes: ["long-polling"],
      version: "1.0",
      minimumVersion: "1.0"
    }

    {handshake_response, client} = send_message(client, handshake_payload)

    {:ok, client } = update_client_cookies(client, handshake_response)

    [parsed_response] = Poison.decode!(handshake_response.body, as: [%Toxic.Bayeux.Handshake{}])

    IO.inspect(parsed_response)

    client =
      Map.update(client, :clientId, parsed_response.clientId, fn _ -> parsed_response.clientId end)

    {:ok, client}
  end

  def subscribe(client, channel) do
    subscribe_payload = %{
      channel: "/meta/subscribe",
      clientId: client.clientId,
      subscription: "Product"
    }

    { handshake_response, client } = send_message(client, subscribe_payload)

    [parsed_response] = Poison.decode!(handshake_response.body, as: [%Toxic.Bayeux.Subscribe{}])

    IO.inspect(parsed_response)

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
