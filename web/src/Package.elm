module Package exposing
    ( Package
    , Release(..)
    , author
    , dependencies
    , doc
    , elmVersion
    , fromRssItem
    , github
    , guid
    , image
    , install
    , license
    , name
    , release
    , releaseTag
    , releases
    , summary
    , time
    , version
    )

import DateFormat
import Rss
import Rss.Item
import Set exposing (Set)
import Time


type Package
    = Package Package_


type alias Package_ =
    { guid : String
    , author : String
    , name : String
    , version : String
    , release : Release
    , summary : String
    , timestamp : Time.Posix
    , doc : String
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
    Just Package_
        |> from (Rss.Item.guid item)
        |> from (rssAuthor item)
        |> from (rssName item)
        |> from (rssVersion item)
        |> from (rssRelease item)
        |> from (description item)
        |> from (Rss.Item.pubDate item)
        |> from (Rss.Item.link item)
        |> from (rssElmVersion item)
        |> from (rssLicense item)
        |> from (Just <| rssDependencies item)
        |> Maybe.map Package


from : Maybe a -> Maybe (a -> b) -> Maybe b
from =
    Maybe.map2 (|>)


rssAuthor : Rss.Item -> Maybe String
rssAuthor item =
    Rss.Item.title item
        |> Maybe.andThen (String.split "/" >> List.head)


rssElmVersion : Rss.Item -> Maybe String
rssElmVersion item =
    Rss.Item.categories item
        |> List.filterMap (withDomain "elm")
        |> List.head


rssLicense : Rss.Item -> Maybe String
rssLicense item =
    Rss.Item.categories item
        |> List.filterMap (withDomain "license")
        |> List.head


rssName : Rss.Item -> Maybe String
rssName item =
    Rss.Item.title item
        |> Maybe.andThen (String.words >> List.head)
        |> Maybe.andThen (String.split "/" >> List.drop 1 >> List.head)


rssRelease : Rss.Item -> Maybe Release
rssRelease item =
    item
        |> rssVersion
        |> Maybe.andThen semVer
        |> Maybe.map semVerRelease


rssVersion : Rss.Item -> Maybe String
rssVersion item =
    case Maybe.map (String.split " ") (Rss.Item.title item) of
        Just [ _, version_ ] ->
            Just version_

        _ ->
            Nothing


author : Package -> String
author (Package pkg) =
    pkg.author


rssDependencies : Rss.Item -> List String
rssDependencies item =
    Rss.Item.categories item
        |> List.filterMap (withDomain "dependency")


withDomain : String -> Rss.Item.Category -> Maybe String
withDomain domain category =
    if category.domain == Just domain then
        Just category.location

    else
        Nothing


dependencies : Package -> List String
dependencies (Package pkg) =
    pkg.dependencies


description : Rss.Item -> Maybe String
description item =
    Rss.Item.description item
        |> Maybe.map String.lines
        |> Maybe.andThen List.head


doc : Package -> String
doc (Package pkg) =
    pkg.doc


elmVersion : Package -> String
elmVersion (Package pkg) =
    pkg.elmVersion


guid : Package -> String
guid (Package pkg) =
    pkg.guid


image : Package -> String
image (Package pkg) =
    "https://github.com/" ++ pkg.author ++ ".png" ++ "?size=32"


install : Package -> String
install (Package pkg) =
    if usesOldPackageSyntax pkg then
        "elm-package install " ++ pkg.author ++ "/" ++ pkg.name

    else
        "elm install " ++ pkg.author ++ "/" ++ pkg.name


github : Package -> String
github (Package pkg) =
    String.join "/"
        [ "https://github.com"
        , pkg.author
        , pkg.name
        , "tree"
        , pkg.version
        ]


license : Package -> String
license (Package pkg) =
    pkg.license


name : Package -> String
name (Package pkg) =
    pkg.name


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


summary : Package -> String
summary (Package pkg) =
    pkg.summary


time : Time.Zone -> Time.Posix -> Package -> String
time tz now (Package pkg) =
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


release : Package -> Release
release (Package pkg) =
    pkg.release


releases : Package -> String
releases (Package pkg) =
    "/?" ++ pkg.author ++ "=" ++ pkg.name


usesOldPackageSyntax : Package_ -> Bool
usesOldPackageSyntax pkg =
    let
        minElmVersion =
            String.slice 4 8 pkg.elmVersion
    in
    if Set.member minElmVersion oldSyntaxVersions then
        True

    else
        False


oldSyntaxVersions : Set String
oldSyntaxVersions =
    Set.fromList
        [ "0.14"
        , "0.14"
        , "0.15"
        , "0.16"
        , "0.17"
        , "0.18"
        ]


version : Package -> String
version (Package pkg) =
    pkg.version
