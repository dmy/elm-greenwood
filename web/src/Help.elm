module Help exposing (view)

import Element as Ui
import Element.Background as Background
import Element.Font as Font
import Element.Region as Region
import Html
import Icon
import Theme exposing (theme)


view : Ui.Element msg
view =
    Ui.column
        [ Ui.paddingXY 8 0
        , Ui.spacing 24
        , Font.size 16
        ]
        [ section "About"
            [ p
                [ "The elm-greenwood.com website provides dynamic web and RSS feeds"
                , " for Elm packages releases."
                , " You can customize the releases, packages and authors included"
                , " in a feed by customizing the URL."
                ]
            , newp
                [ "The browser will refresh feeds every 5 minutes, the server"
                , " is synchonized to the official elm server every minute."
                ]
            , newp
                [ "Feeds are quite arbitrary limited to 42 items." ]
            ]
        , section "Releases filtering based on semantic versioning "
            [ urlExample "/" "Packages all releases"
            , urlExample "/last" "Packages last release (per elm version constraint)"
            , urlExample "/first" "Packages first release"
            , urlExample "/major" "Packages major releases"
            , urlExample "/minor" "Packages minor releases"
            , urlExample "/patch" "Packages patch releases"
            , Ui.paragraph [ Ui.paddingEach { edges | top = theme.space.m } ]
                [ Ui.text "The website returns all releases by default,"
                , Ui.text " and the "
                , Ui.el [] (Icon.logo 24)
                , Ui.text " logo can be clicked to return to this feed."
                ]
            , newp
                [ "The search results return last packages release instead."
                ]
            ]
        , section "Packages filtering with query parameters"
            [ p [ "The format of the query parameters is:" ]
            , command "author=package[+package2][+...]"
            , Ui.paragraph []
                [ Ui.text " A wildcard "
                , code [] "'*'"
                , Ui.text " can be used to request all packages from an author."
                , Ui.text " Last releases from an author can also be displayed by"
                , Ui.text " clicking the github avatar in the package release details."
                ]
            , newp
                [ "It is also possible to use a search query to find packages"
                , " containing the string in their name or summary:"
                ]
            , command "_search=string"
            , p [ "This is the query used when using the search box." ]
            , newp []
            , Ui.paragraph []
                [ Ui.text " Several query parameters can be specified with "
                , code [] "'&'"
                , Ui.text ", but at most one search query can be used."
                ]
            , Ui.el
                [ Font.semiBold
                , Ui.paddingEach { edges | top = theme.space.m, bottom = theme.space.s }
                ]
                (Ui.text "Examples:")
            , urlExample "/last?elm=*" "Last releases from elm organization"
            , urlExample "/major?elm=parser+bytes" "Major releases of elm/parser and elm/bytes"
            , urlExample "/?elm-explorations=*" "All releases from elm-explorations"
            , urlExample "/?elm=*&elm-explorations=*" "All releases from elm and elm-explorations"
            , urlExample "/last?_search=elm-ui" "Last releases matching \"elm-ui\""
            , urlExample "/major?_search=router&elm=url" "Major releases from packages matching \"router\" or from elm/url"
            ]
        , section "RSS feeds"
            [ Ui.paragraph []
                [ Ui.text "You can create an RSS feed by adding "
                , code [] "\"/.rss\""
                , Ui.text " to the end of an URL"
                , Ui.text ", before the optional query parameters, "
                , Ui.text " or by clicking the header "
                , Ui.el [ Font.color theme.link ] (Icon.rssFeed 16)
                , Ui.text " icon link to get the current feed."
                ]
            , Ui.el
                [ Font.semiBold
                , Ui.paddingEach { edges | top = 8, bottom = 4 }
                ]
                (Ui.text "Examples:")
            , urlExample "/last/.rss" "RSS for last releases"
            , urlExample "/.rss?elm=*" "RSS for all releases from elm organization"
            , urlExample "/.rss?_search=elm-ui" "RSS for all releases matching \"elm-ui\""
            ]
        , section "Elm project dependencies feed"
            [ Ui.paragraph []
                [ Ui.text "To generate an RSS feed for your projects dependencies,"
                , Ui.text " install "
                , code [] "elm-deps-rss"
                , Ui.text ":"
                ]
            , command "npm install -g elm-deps-rss"
            , Ui.paragraph []
                [ Ui.text "And run it from an elm project directory with the "
                , code [] "elm.json"
                , Ui.text " file:"
                ]
            , command "elm-deps-rss"
            ]
        , section "Issues & feedback"
            [ link "https://github.com/dmy/elm-greenwood/issues"
            ]
        , section "License"
            [ p [ "BSD 3-Clause" ]
            ]
        ]


command : String -> Ui.Element msg
command cmd =
    code [ Ui.paddingXY theme.space.l theme.space.m ] cmd


code : List (Ui.Attribute msg) -> String -> Ui.Element msg
code attrs source =
    Ui.el
        (Font.family
            [ Font.typeface "Source Code Pro"
            , Font.monospace
            ]
            :: Font.size theme.font.size.s
            :: Ui.width Ui.fill
            :: attrs
        )
        (Ui.html <| Html.code [] [ Html.text source ])


urlExample : String -> String -> Ui.Element msg
urlExample url description =
    Ui.column
        [ Ui.width Ui.fill
        ]
        [ p [ description, ":" ]
        , link url
        ]


newp : List String -> Ui.Element msg
newp strings =
    Ui.paragraph
        [ Ui.paddingEach { top = 8, left = 0, right = 0, bottom = 0 } ]
        (List.map Ui.text strings)


p : List String -> Ui.Element msg
p strings =
    Ui.paragraph [] (List.map Ui.text strings)


link : String -> Ui.Element msg
link url =
    Ui.paragraph []
        [ Ui.link
            [ Font.color theme.link
            , Ui.paddingEach { edges | left = theme.space.l, bottom = theme.space.xs }
            , Ui.mouseOver
                [ Font.color theme.overLink ]
            ]
            { url = url
            , label = Ui.text url
            }
        ]


section : String -> List (Ui.Element msg) -> Ui.Element msg
section title elms =
    Ui.column [ Ui.spacing 4 ]
        [ Ui.paragraph
            [ Region.heading 1
            , Font.semiBold
            , Font.size 20
            , Ui.paddingXY 0 4
            ]
            [ Ui.text title ]
        , Ui.column [ Ui.spacing 4 ] elms
        ]


edges : { top : Int, right : Int, bottom : Int, left : Int }
edges =
    { top = 0
    , right = 0
    , bottom = 0
    , left = 0
    }
