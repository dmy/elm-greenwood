module Package exposing
    ( Package
    , Release(..)
    , dependencies
    , doc
    , fromRssItem
    , github
    , id
    , image
    , install
    , releaseTag
    , releases
    , time
    )

import DateFormat
import Rss exposing (Item)
import Rss.Item
import Set exposing (Set)
import Time


type alias Package =
    { author : String
    , name : String
    , version : String
    , release : Release
    , description : String
    , timestamp : Time.Posix
    , elmVersion : String
    , license : String
    , dependencies : List String
    }


type alias SemVer =
    { major : Int
    , minor : Int
    , patch : Int
    }


type Release
    = New
    | Major
    | Minor
    | Patch


fromRssItem : Rss.Item -> Maybe Package
fromRssItem item =
    Just Package
        |> from (author item)
        |> from (name item)
        |> from (version item)
        |> from (release item)
        |> from (Rss.Item.description item)
        |> from (Rss.Item.pubDate item)
        |> from (elmVersion item)
        |> from (license item)
        |> from (Just <| dependencies item)


from : Maybe a -> Maybe (a -> b) -> Maybe b
from =
    Maybe.map2 (|>)


id : Package -> String
id pkg =
    pkg.author ++ pkg.name ++ pkg.version


name : Rss.Item -> Maybe String
name item =
    Rss.Item.title item
        |> Maybe.andThen (String.words >> List.head)
        |> Maybe.andThen (String.split "/" >> List.drop 1 >> List.head)


author : Rss.Item -> Maybe String
author item =
    Rss.Item.title item
        |> Maybe.andThen (String.split "/" >> List.head)


version : Rss.Item -> Maybe String
version item =
    case Maybe.map (String.split " ") (Rss.Item.title item) of
        Just [ _, version_ ] ->
            Just version_

        _ ->
            Nothing


release : Rss.Item -> Maybe Release
release item =
    item
        |> version
        |> Maybe.andThen semVer
        |> Maybe.map semVerRelease


semVer : String -> Maybe SemVer
semVer ver =
    case String.split "." ver |> List.filterMap String.toInt of
        [ major, minor, patch ] ->
            Just (SemVer major minor patch)

        _ ->
            Nothing


semVerRelease : SemVer -> Release
semVerRelease v =
    if v == { major = 1, minor = 0, patch = 0 } then
        New

    else if v.minor == 0 && v.patch == 0 then
        Major

    else if v.patch == 0 then
        Minor

    else
        Patch


time : Time.Zone -> Time.Posix -> Package -> String
time tz now pkg =
    let
        seconds =
            (Time.posixToMillis now - Time.posixToMillis pkg.timestamp) // 1000

        minutes =
            seconds // 60

        hours =
            minutes // 60

        days =
            hours // 24
    in
    if seconds < 60 then
        "just now"

    else if minutes == 1 then
        "a minute ago"

    else if minutes < 60 then
        String.fromInt minutes ++ " minutes ago"

    else if hours == 1 then
        "an hour ago"

    else if hours < 24 then
        String.fromInt hours ++ " hours ago"

    else if days == 1 then
        "a day ago"

    else if days < 7 then
        String.fromInt days ++ " days ago"

    else
        DateFormat.format
            [ DateFormat.monthNameFull
            , DateFormat.text " "
            , DateFormat.dayOfMonthNumber
            , DateFormat.text ", "
            , DateFormat.yearNumber
            ]
            tz
            pkg.timestamp


releaseTag : Release -> String
releaseTag pkgRelease =
    case pkgRelease of
        New ->
            "new"

        Major ->
            "major"

        Minor ->
            "minor"

        Patch ->
            "patch"


elmVersion : Rss.Item -> Maybe String
elmVersion item =
    Rss.Item.categories item
        |> List.filterMap (withDomain "elm")
        |> List.head


license : Rss.Item -> Maybe String
license item =
    Rss.Item.categories item
        |> List.filterMap (withDomain "license")
        |> List.head


dependencies : Rss.Item -> List String
dependencies item =
    Rss.Item.categories item
        |> List.filterMap (withDomain "dependency")


withDomain : String -> Rss.Item.Category -> Maybe String
withDomain domain category =
    if category.domain == Just domain then
        Just category.location

    else
        Nothing


image : Package -> String
image pkg =
    "https://github.com/" ++ pkg.author ++ ".png" ++ "?size=32"


doc : Package -> String
doc pkg =
    String.join "/"
        [ "https://package.elm-lang.org/packages"
        , pkg.author
        , pkg.name
        , pkg.version
        ]


github : Package -> String
github pkg =
    String.join "/"
        [ "https://github.com"
        , pkg.author
        , pkg.name
        , "tree"
        , pkg.version
        ]


releases : Package -> String
releases pkg =
    "/?" ++ pkg.author ++ "=" ++ pkg.name


install : Package -> String
install pkg =
    let
        minElmVersion =
            String.slice 4 8 pkg.elmVersion
    in
    if Set.member minElmVersion oldSyntaxVersions then
        "elm-package install " ++ pkg.author ++ "/" ++ pkg.name

    else
        "elm install " ++ pkg.author ++ "/" ++ pkg.name


oldSyntaxVersions : Set String
oldSyntaxVersions =
    Set.fromList
        [ "0.14"
        , "0.15"
        , "0.16"
        , "0.17"
        , "0.18"
        ]
