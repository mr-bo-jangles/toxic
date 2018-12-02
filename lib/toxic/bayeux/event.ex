defmodule Toxic.Bayeux.Event do
  @moduledoc false
  defstruct [
    :data,
    :channel
  ]
end
defmodule Toxic.Bayeux.Event.Data do
  defstruct [
    :event,
    :sobject
  ]
end
defmodule Toxic.Bayeux.Event.Data.Event do
  defstruct [
    :createdDate,
    :replayId,
    :type
  ]
end
defmodule Toxic.Bayeux.Event.Data.SObject do
  defstruct [
    :OwnerId,
    :Id,
    :Name
  ]
end
#
#"""
#[
#  {
#    "data": {
#      "event": {
#        "createdDate": "2018-11-23T15:17:46.290Z",
#        "replayId": 3,
#        "type": "updated"
#      },
#      "sobject": {
#        "OwnerId": "0051t000001P5HiAAK",
#        "Id": "a001t0000040NZBAA2",
#        "Name": "Dragonite"
#      }
#    },
#    "channel": "/topic/Monster"
#  },
#  {
#    "clientId": "5631b4kb9cimkjr61sij080jygd1p",
#    "channel": "/meta/connect",
#    "id": "4",
#    "successful": true
#  }
#]
#"""
#
#"""
#[
#   {
#      "data":{
#         "event":{
#            "createdDate":"2018-11-23T15:03:48.857Z",
#            "replayId":1,
#            "type":"created"
#         },
#         "sobject":{
#            "OwnerId":"0051t000001P5HiAAK",
#            "Id":"a001t0000040NXAAA2",
#            "Name":"Drake"
#         }
#      },
#      "channel":"/topic/Monster"
#   },
#   {
#      "clientId":"5o01uphzp15ukmr0tj9y2fvx8v2j",
#      "channel":"/meta/connect",
#      "id":"4",
#      "successful":true
#   }
#]
#"""
