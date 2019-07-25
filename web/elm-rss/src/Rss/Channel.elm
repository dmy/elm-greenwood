module Rss.Channel exposing
    ( Channel
    , title, link, description
    , items
    , language, copyright, managingEditor, webMaster
    , pubDate, lastBuildDate
    , categories
    , generator, docs
    , cloud, Cloud
    , ttl
    , image, Image
    , rating
    , textInput, TextInput
    , skipHours, skipDays
    , decoder
    )

{-|

@docs Channel


# Required channel elements

@docs title, link, description


# Optional channel elements

@docs items
@docs language, copyright, managingEditor, webMaster
@docs pubDate, lastBuildDate
@docs categories
@docs generator, docs
@docs cloud, Cloud
@docs ttl
@docs image, Image
@docs rating
@docs textInput, TextInput
@docs skipHours, skipDays


# Decoder

@docs decoder

-}

import Imf.DateTime
import Rss.Item as Item exposing (Category, Item)
import Time exposing (Weekday(..))
import Xml.Decode exposing (..)


{-| A `Channel` contains information about the channel (metadata) and its contents.
-}
type Channel
    = Channel Channel_


type alias Channel_ =
    { title : String
    , link : String
    , description : String
    , items : List Item
    , language : Maybe String
    , copyright : Maybe String
    , managingEditor : Maybe String
    , webMaster : Maybe String
    , pubDate : Maybe Time.Posix
    , lastBuildDate : Maybe Time.Posix
    , categories : List Category
    , generator : Maybe String
    , docs : Maybe String
    , cloud : Maybe Cloud
    , ttl : Maybe Int
    , image : Maybe Image
    , rating : Maybe String
    , textInput : Maybe TextInput
    , skipHours : List Int
    , skipDays : List Time.Weekday
    }



-- REQUIRED CHANNEL ELEMENTS


{-| The name of the channel. It's how people refer to your service.
If you have an HTML website that contains the same information as your RSS file,
the title of your channel should be the same as the title of your website.
-}
title : Channel -> String
title (Channel channel) =
    channel.title


{-| The URL to the HTML website corresponding to the channel.
-}
link : Channel -> String
link (Channel channel) =
    channel.link


{-| Phrase or sentence describing the channel.
-}
description : Channel -> String
description (Channel channel) =
    channel.description



-- OPTIONAL CHANNEL ELEMENTS


{-| A channel may contain any number of [`Rss.Item`](Rss.Item#Item).
-}
items : Channel -> List Item
items (Channel channel) =
    channel.items


{-| The language the channel is written in.
This allows aggregators to group all Italian language sites, for example,
on a single page. A list of allowable values for this element, as provided by
Netscape, is [here](http://www.rssboard.org/rss-language-codes).
[Values defined](http://www.w3.org/TR/REC-html40/struct/dirlang.html#langcodes)
by the W3C may also be used.
-}
language : Channel -> Maybe String
language (Channel channel) =
    channel.language


{-| Copyright notice for content in the channel.
-}
copyright : Channel -> Maybe String
copyright (Channel channel) =
    channel.copyright


{-| Email address for person responsible for editorial content.
-}
managingEditor : Channel -> Maybe String
managingEditor (Channel channel) =
    channel.managingEditor


{-| Email address for person responsible for technical issues relating
to channel.
-}
webMaster : Channel -> Maybe String
webMaster (Channel channel) =
    channel.webMaster


{-| The publication date for the content in the channel.
For example, the New York Times publishes on a daily basis, the publication
date flips once every 24 hours. That's when the pubDate of the channel changes.
-}
pubDate : Channel -> Maybe Time.Posix
pubDate (Channel channel) =
    channel.pubDate


{-| The last time the content of the channel changed.
-}
lastBuildDate : Channel -> Maybe Time.Posix
lastBuildDate (Channel channel) =
    channel.lastBuildDate


{-| A list of [`Category`](Rss.Item#Category) that the channel belongs to.
-}
categories : Channel -> List Category
categories (Channel channel) =
    channel.categories


{-| A string indicating the program used to generate the channel.
-}
generator : Channel -> Maybe String
generator (Channel channel) =
    channel.generator


{-| A URL that points to the documentation for the format used in the RSS file.
It's probably a pointer to the
[RSS 2.0 specification](http://www.rssboard.org/rss-specification).
It's for people who might stumble across an RSS file on a Web server 25 years
from now and wonder what it is.
-}
docs : Channel -> Maybe String
docs (Channel channel) =
    channel.docs


{-| Allows processes to register with a cloud to be notified of updates to the
channel, implementing a lightweight publish-subscribe protocol for RSS feeds.
More info [here](http://www.rssboard.org/rss-specification#ltcloudgtSubelementOfLtchannelgt).
-}
cloud : Channel -> Maybe Cloud
cloud (Channel channel) =
    channel.cloud


{-| The RssCloud Application Programming Interface (API) is an XML-RPC, SOAP 1.1
and REST web service that enables client software to be notified of updates to
RSS documents. A server (called the "cloud") takes notification requests for
particular RSS documents. More info
[here](http://www.rssboard.org/rsscloud-interface).
-}
type alias Cloud =
    { domain : String
    , port_ : Int
    , path : String
    , registerProcedure : String
    , protocol : String
    }


{-| ttl stands for time to live.
It's a number of minutes that indicates how long a channel can be cached before
refreshing from the source.
-}
ttl : Channel -> Maybe Int
ttl (Channel channel) =
    channel.ttl


{-| Specifies a GIF, JPEG or PNG image that can be displayed with the channel.
-}
image : Channel -> Maybe Image
image (Channel channel) =
    channel.image


{-| An `Image` contains three required and three optional sub-elements.

  - `url` is the URL of a GIF, JPEG or PNG image that represents the channel.
  - `title` describes the image, it's used in the ALT attribute of the HTML <img>
    tag when the channel is rendered in HTML.
  - `link` is the URL of the site, when the channel is rendered, the image is a
    link to the site. (Note, in practice the `Image` `title` and `link` should have
    the same value as the channel's [`title`](#title) and [`link`](#link).

Optional elements include `width` and `height` numbers, indicating the width
and height of the image in pixels. `description` contains text that is included
in the TITLE attribute of the link formed around the image in the HTML
rendering.

Maximum value for width is 144, default value is 88.
Maximum value for height is 400, default value is 31.

-}
type alias Image =
    { url : String
    , title : String
    , link : String
    , width : Maybe Int
    , height : Maybe Int
    , description : Maybe String
    }


{-| The [PICS](https://www.w3.org/PICS/) rating for the channel.
-}
rating : Channel -> Maybe String
rating (Channel channel) =
    channel.rating


{-| Specifies a text input box that can be displayed with the channel.

The purpose of the `textInput` element is something of a mystery.
It can be used to specify a search engine box.
Or to allow a reader to provide feedback.
Most aggregators ignore it.

-}
textInput : Channel -> Maybe TextInput
textInput (Channel channel) =
    channel.textInput


{-| A `TextInput` contains four required sub-elements.

  - `title`: The label of the Submit button in the text input area.
  - `description`: Explains the text input area.
  - `name`: The name of the text object in the text input area.
  - `link`: The URL of the CGI script that processes text input requests.

-}
type alias TextInput =
    { title : String
    , description : String
    , name : String
    , link : String
    }


{-| A hint for aggregators telling them which hours they can skip.
This element contains up to 24 `Int` sub-elements whose value is a number
between 0 and 23, representing a time in GMT, when aggregators, if they support
the feature, may not read the channel on hours listed in the `skipHours`
element. The hour beginning at midnight is hour zero.
-}
skipHours : Channel -> List Int
skipHours (Channel channel) =
    channel.skipHours


{-| A hint for aggregators telling them which days they can skip.
This element contains up to seven
[`Weekday`](https://package.elm-lang.org/packages/elm/time/1.0.0/Time#Weekday).
Aggregators may not read the channel during days listed in the `skipDays`
element.
-}
skipDays : Channel -> List Time.Weekday
skipDays (Channel channel) =
    channel.skipDays



-- DECODERS


{-| [`Rss.Channel`](#Channel)
[`Xml.Decode.Decoder`](https://package.elm-lang.org/packages/dmy/elm-xml/latest/Xml-Decode#Decoder).
You most likely want to use [`Rss.decode`](Rss#decode) instead.
-}
decoder : Decoder Channel
decoder =
    succeed Channel_
        |> from (element "title" string)
        |> from (element "link" string)
        |> from (element "description" string)
        |> from (elements "item" Item.decoder)
        |> from (maybe (element "language" string))
        |> from (maybe (element "copyright" string))
        |> from (maybe (element "managingEditor" string))
        |> from (maybe (element "webMaster" string))
        |> from (maybe (element "pubDate" date))
        |> from (maybe (element "lastBuildDate" date))
        |> from (elements "category" category)
        |> from (maybe (element "generator" string))
        |> from (maybe (element "docs" string))
        |> from (maybe (element "cloud" cloudDecoder))
        |> from (maybe (element "ttl" int))
        |> from (maybe (element "image" imageDecoder))
        |> from (maybe (element "rating" string))
        |> from (maybe (element "textInput" textInputDecoder))
        |> from (maybeWithDefault [] (element "skipHours" skipHoursDecoder))
        |> from (maybeWithDefault [] (element "skipDays" skipDaysDecoder))
        |> map Channel


date : Decoder Time.Posix
date =
    string |> andThen checkDate


checkDate : String -> Decoder Time.Posix
checkDate str =
    case Imf.DateTime.toPosix str of
        Ok posix ->
            succeed posix

        Err _ ->
            fail "Invalid date"


category : Decoder Category
category =
    map2 Category
        (maybe (attribute "domain" string))
        string


cloudDecoder : Decoder Cloud
cloudDecoder =
    map5 Cloud
        (attribute "domain" string)
        (attribute "port" int)
        (attribute "path" string)
        (attribute "registerProcedure" string)
        (attribute "protocol" string)


imageDecoder : Decoder Image
imageDecoder =
    succeed Image
        |> from (element "url" string)
        |> from (element "title" string)
        |> from (element "link" string)
        |> from (maybe (element "width" int))
        |> from (maybe (element "height" int))
        |> from (maybe (element "description" string))


textInputDecoder : Decoder TextInput
textInputDecoder =
    map4 TextInput
        (element "title" string)
        (element "description" string)
        (element "name" string)
        (element "link" string)


skipHoursDecoder : Decoder (List Int)
skipHoursDecoder =
    elements "hour" int


skipDaysDecoder : Decoder (List Time.Weekday)
skipDaysDecoder =
    elements "day" string
        |> map (List.filterMap stringToWeekday)


stringToWeekday : String -> Maybe Weekday
stringToWeekday str =
    case str of
        "Monday" ->
            Just Mon

        "Tuesday" ->
            Just Tue

        "Wednesday" ->
            Just Wed

        "Thursday" ->
            Just Thu

        "Friday" ->
            Just Fri

        "Saturday" ->
            Just Sat

        "Sunday" ->
            Just Sun

        -- Maybe fail instead?
        _ ->
            Nothing
