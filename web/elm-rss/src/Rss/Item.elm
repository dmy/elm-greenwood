module Rss.Item exposing
    ( Item
    , title, description
    , link, author
    , categories, Category
    , comments, enclosure, guid, pubDate, source
    , decoder
    )

{-|

@docs Item


# Optional item elements

@docs title, description
@docs link, author
@docs categories, Category
@docs comments, enclosure, guid, pubDate, source


# Decoder

@docs decoder

-}

import Imf.DateTime
import Time
import Xml.Decode exposing (..)


{-| An item may represent a "story" -- much like a story in a newspaper or magazine; if so its description is a synopsis of the story, and the link points to the full story. An item may also be complete in itself, if so, the description contains the text (entity-encoded HTML is allowed), and the link and title may be omitted. All elements of an item are optional, however at least one of title or description must be present.
-}
type Item
    = Item Item_


type alias Item_ =
    { title : Maybe String
    , description : Maybe String
    , link : Maybe String
    , author : Maybe String
    , categories : List Category
    , comments : Maybe String
    , enclosure : Maybe String
    , guid : Maybe String
    , pubDate : Maybe Time.Posix
    , source : Maybe String
    }



-- OPTIONAL ITEM ELEMENTS


{-| The title of the item.

At least one of title or description must be present.

-}
title : Item -> Maybe String
title (Item item) =
    item.title


{-| The item synopsis.

At least one of title or description must be present.

-}
description : Item -> Maybe String
description (Item item) =
    item.description


{-| The URL of the item.
-}
link : Item -> Maybe String
link (Item item) =
    item.link


{-| Email address of the author of the item.
More info
[here](http://www.rssboard.org/rss-specification#ltauthorgtSubelementOfLtitemgt).
-}
author : Item -> Maybe String
author (Item item) =
    item.author


{-| A list of [`Category`](#Category) that the item belongs to.
-}
categories : Item -> List Category
categories (Item item) =
    item.categories


{-| Each category has an optional domain that identifies a categorization taxonomy,
and a hierarchic location in the indicated taxonomy represented by a
`List String`.

For example, given the following categories:

    [ { domain = Just "www.dmoz.com", location = [ "Computers", "Internet" ] }
    , { domain = Nothing, location = [ "News" ] }
    , { domain = Nothing, location = [ "Tutorial" ] }
    ]

The first category hierarchic location is `Computers/Internet` in the
[www.dmoz.com](https://www.dmoz.com) domain.

-}
type alias Category =
    { domain : Maybe String
    , location : String
    }


{-| URL of a page for comments relating to the item.
More info
[here](http://www.rssboard.org/rss-specification#ltcommentsgtSubelementOfLtitemgt).
-}
comments : Item -> Maybe String
comments (Item item) =
    item.comments


{-| Describes a media object that is attached to the item.
More info
[here](http://www.rssboard.org/rss-specification#ltenclosuregtSubelementOfLtitemgt).
-}
enclosure : Item -> Maybe String
enclosure (Item item) =
    item.enclosure


{-| A string that uniquely identifies the item.
More info
[here](http://www.rssboard.org/rss-specification#ltguidgtSubelementOfLtitemgt).
-}
guid : Item -> Maybe String
guid (Item item) =
    item.guid


{-| Indicates when the item was published.
More info
[here](http://www.rssboard.org/rss-specification#ltpubdategtSubelementOfLtitemgt).
-}
pubDate : Item -> Maybe Time.Posix
pubDate (Item item) =
    item.pubDate


{-| The RSS channel that the item came from.
More info
[here](http://www.rssboard.org/rss-specification#ltsourcegtSubelementOfLtitemgt).
-}
source : Item -> Maybe String
source (Item item) =
    item.source



-- DECODERS


{-| [`Rss.Item`](#Item) [`Xml.Decode.Decoder`](https://package.elm-lang.org/packages/dmy/elm-xml/latest/Xml-Decode#Decoder).
You most likely want to use [`Rss.decode`](Rss#decode) instead.
-}
decoder : Decoder Item
decoder =
    succeed Item_
        |> from (maybe (element "title" string))
        |> from (maybe (element "description" string))
        |> from (maybe (element "link" string))
        |> from (maybe (element "author" string))
        |> from (elements "category" category)
        |> from (maybe (element "comments" string))
        |> from (maybe (element "enclosure" string))
        |> from (maybe (element "guid" string))
        |> from (maybe (element "pubDate" date))
        |> from (maybe (element "source" string))
        |> map Item


category : Decoder Category
category =
    map2 Category
        (maybe (attribute "domain" string))
        string


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
