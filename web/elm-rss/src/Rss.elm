module Rss exposing
    ( Rss
    , version, channel
    , decode, decoder
    , Channel, Item
    )

{-|

@docs Rss

@docs version, channel


# Decoder

@docs decode, decoder

-}

import Rss.Channel as Channel
import Rss.Item as Item
import Xml.Decode as Xml exposing (..)


{-| At the top level, a RSS document is a [`Rss`](Rss#Rss) element.
-}
type Rss
    = Rss Rss_


{-| Exposed for convenience. This allows to use a
[`Channel`](Rss-Channel#Channel) with `Rss.Channel`.
-}
type alias Channel =
    Channel.Channel


{-| Exposed for convenience. This allows to use an
[`Item`](Rss-Item#Item) with `Rss.Item`.
-}
type alias Item =
    Item.Item


type alias Rss_ =
    { version : String
    , channel : Channel
    }


{-| Parse the given XML string into an [`Rss`](Rss#Rss).

This will fail if the RSS document is not conform to
[RSS 2.0 specification](http://www.rssboard.org/rss-specification).

-}
decode : String -> Result Errors Rss
decode xml =
    Xml.decodeString decoder xml


{-| [`Rss`](Rss#Rss) [`Xml.Decode.Decoder`](https://package.elm-lang.org/packages/dmy/elm-xml/latest/Xml-Decode#Decoder).
You most likely want to use [`Rss.decode`](Rss#decode) instead.
-}
decoder : Decoder Rss
decoder =
    map2 Rss_
        (attribute "version" string)
        (path [ "rss", "channel" ] Channel.decoder)
        |> map Rss


{-| A [`Rss`](Rss#Rss) element has a mandatory attribute called version,
that specifies the version of RSS that the document conforms to.
If it conforms to the
[RSS 2.0 specification](http://www.rssboard.org/rss-specification),
the version attribute must be `"2.0"`.
-}
version : Rss -> String
version (Rss rss) =
    rss.version


{-| Subordinate to the [`Rss`](Rss#Rss) element is a single
[`Channel`](Rss.Channel#Channel) element.
-}
channel : Rss -> Channel
channel (Rss rss) =
    rss.channel
