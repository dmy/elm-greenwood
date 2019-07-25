module Main exposing (main)

import Browser exposing (UrlRequest)
import Browser.Events
import Browser.Navigation as Nav
import Element as Ui
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Element.Lazy as Lazy
import Help
import Html
import Html.Attributes exposing (attribute, class, title)
import Html.Events
import Http
import Icon
import Json.Decode
import Json.Encode
import Package exposing (Package)
import Rss exposing (Rss)
import Rss.Channel
import Set exposing (Set)
import Svg
import Svg.Attributes as SvgA
import Task
import Theme exposing (theme)
import Time
import Url exposing (Url)
import Url.Parser exposing ((<?>))
import Url.Parser.Query
import Xml.Decode as Xml


type alias Flags =
    { now : Int
    , width : Int
    }


type alias Model =
    { navKey : Nav.Key
    , url : Url
    , page : Page
    , unfolded : Set String
    , search : String
    , now : Time.Posix
    , tz : Time.Zone
    , width : Int
    }


type Page
    = Rss Loading Feed
    | Help
    | Error


type alias Feed =
    { title : String
    , packages : List Package
    }


type Loading
    = Loading
    | Loaded


type Msg
    = PackageClicked String
    | RssUpdated (Result Xml.Errors Feed)
    | SearchInputChanged String
    | SearchRequested
    | UpdateRequested Time.Posix
    | UrlChanged Url
    | UrlRequested UrlRequest
    | WindowResized Int Int



-- INIT


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        newUrl =
            canonicalizeUrl url

        page =
            getPage newUrl (Rss Loading loadingFeed)
    in
    ( { navKey = navKey
      , url = newUrl
      , page = page
      , unfolded = Set.empty
      , search = ""
      , now = Time.millisToPosix flags.now
      , tz = Time.utc
      , width = flags.width
      }
    , Nav.replaceUrl navKey (Url.toString newUrl)
    )



-- URL


paths : Set String
paths =
    Set.fromList
        [ "/last"
        , "/first"
        , "/major"
        , "/minor"
        , "/patch"
        , "/help"
        ]


canonicalizeUrl : Url -> Url
canonicalizeUrl url =
    if Set.member url.path paths then
        { url | path = url.path }

    else
        { url | path = "/" }


getPage : Url -> Page -> Page
getPage url page =
    case url.path of
        "/help" ->
            Help

        _ ->
            load page


getSearchQuery : Url -> String
getSearchQuery url =
    Maybe.withDefault "" <|
        Maybe.withDefault Nothing <|
            Url.Parser.parse
                (Url.Parser.top <?> Url.Parser.Query.string "_search")
                { url | path = "/" }


load : Page -> Page
load page =
    case page of
        Rss Loaded currentFeed ->
            -- keep current packages until the new ones are loaded
            Rss Loading { loadingFeed | packages = currentFeed.packages }

        _ ->
            Rss Loading loadingFeed


loadingFeed : Feed
loadingFeed =
    { title = "Loading feed..."
    , packages = []
    }



-- RSS REQUESTS


getRss : Url -> Cmd Msg
getRss url =
    case url.path of
        "/help" ->
            Cmd.none

        _ ->
            Http.get
                { url = Url.toString (rssFeed url)
                , expect = expectRss RssUpdated
                }


rssFeed : Url -> Url
rssFeed url =
    if String.endsWith "/" url.path then
        { url | path = url.path ++ ".rss" }

    else
        { url | path = url.path ++ "/.rss" }


expectRss : (Result Xml.Errors Feed -> msg) -> Http.Expect msg
expectRss toMsg =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.GoodStatus_ _ body ->
                    case Rss.decode body of
                        Ok rss ->
                            let
                                channel =
                                    Rss.channel rss
                            in
                            Rss.Channel.items channel
                                |> List.filterMap Package.fromRssItem
                                |> Feed (Rss.Channel.title channel)
                                |> Ok

                        Err errors ->
                            Err errors

                _ ->
                    Err [ Xml.Error "HTTP error" ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Elm Greenwood"
    , body =
        [ Ui.layoutWith
            { options = layoutOptions }
            [ Font.family theme.font.family
            , Background.color theme.background
            , style "-webkit-tap-highlight-color" "transparent"
            ]
            (Ui.column
                [ Ui.width Ui.fill
                , Ui.height Ui.fill
                ]
                [ viewHeader model
                , Ui.el
                    [ Ui.width (Ui.fill |> Ui.maximum 768)
                    , Ui.height Ui.fill
                    , Ui.scrollbarY
                    , Ui.centerX
                    , Ui.padding theme.space.m
                    ]
                    (viewPage model)
                , viewFooter model.tz model.now
                ]
            )
        ]
    }


layoutOptions : List Ui.Option
layoutOptions =
    [ Ui.focusStyle
        { borderColor = Nothing
        , backgroundColor = Nothing
        , shadow = Nothing
        }
    ]


viewHeader : Model -> Ui.Element Msg
viewHeader model =
    Ui.row
        [ Ui.width (Ui.fill |> Ui.maximum 768)
        , Ui.spacing (model.width // 20)
        , Ui.padding theme.space.m
        , Ui.centerX
        ]
        [ viewLogo
        , Ui.column
            [ Ui.width Ui.fill
            , Ui.height Ui.fill
            , Ui.spacing theme.space.m
            ]
            [ viewSearchBox model.search
            , viewNavigation model.url
            ]
        ]


viewSearchBox : String -> Ui.Element Msg
viewSearchBox input =
    Input.text
        [ Input.focusedOnLoad
        , Border.rounded 0
        , Border.color theme.searchBox
        , Border.width 1
        , Ui.paddingEach
            { edges
                | top = theme.space.m
                , right = theme.space.xl
                , bottom = theme.space.m
                , left = theme.space.m
            }
        , Font.size theme.font.size.m
        , onEnter SearchRequested
        , Ui.inFront searchButton
        ]
        { onChange = SearchInputChanged
        , text = input
        , placeholder = Nothing
        , label = Input.labelHidden "search"
        }


searchButton : Ui.Element Msg
searchButton =
    Input.button
        [ Ui.paddingXY theme.space.m 0
        , Ui.alignRight
        , Ui.centerY
        , Ui.htmlAttribute (title "Search")
        , onBlockedClick SearchRequested
        , Ui.pointer
        , Font.color theme.searchBox
        , Ui.mouseDown
            [ Font.color theme.overLink ]
        ]
        { onPress = Nothing
        , label = Icon.search
        }


onBlockedClick : msg -> Ui.Attribute msg
onBlockedClick msg =
    Ui.htmlAttribute <|
        Html.Events.custom "click" <|
            Json.Decode.succeed
                { message = msg
                , stopPropagation = True
                , preventDefault = True
                }


onKey : Int -> msg -> Ui.Attribute msg
onKey keyCode msg =
    Ui.htmlAttribute <|
        Html.Events.on "keyup" <|
            Json.Decode.andThen
                (\keyUp ->
                    if keyUp == keyCode then
                        Json.Decode.succeed msg

                    else
                        Json.Decode.fail (String.fromInt keyUp)
                )
                Html.Events.keyCode


onEnter : msg -> Ui.Attribute msg
onEnter msg =
    onKey 13 msg


viewNavigation : Url -> Ui.Element msg
viewNavigation currentUrl =
    Ui.row
        [ Ui.width Ui.fill
        , Ui.height Ui.fill
        , Ui.spaceEvenly
        , Font.size theme.font.size.m
        ]
        [ navLink currentUrl { url = "/last", label = "Last" }
        , navLink currentUrl { url = "/first", label = "First" }
        , navLink currentUrl { url = "/major", label = "Major" }
        , navLink currentUrl { url = "/minor", label = "Minor" }
        , navLink currentUrl { url = "/patch", label = "Patch" }
        , navLink currentUrl { url = "/help", label = "Help" }
        ]


navLink : Url -> { url : String, label : String } -> Ui.Element msg
navLink currentUrl config =
    Ui.link
        [ if currentUrl.path == config.url then
            Font.color theme.overLink

          else
            Font.color theme.link
        , attrIf (currentUrl.path == config.url) <|
            \_ -> Font.underline
        , Ui.alignBottom
        , Ui.mouseOver
            [ Font.color theme.overLink
            ]
        ]
        { url = config.url
        , label = Ui.text config.label
        }


viewLogo : Ui.Element msg
viewLogo =
    Ui.link []
        { url = "/"
        , label =
            Ui.el
                [ Ui.width (Ui.px 60)
                , Ui.height (Ui.px 60)
                , Ui.moveUp 2
                , Ui.centerX
                , Ui.htmlAttribute (title "All releases")
                ]
                (Icon.logo 60)
        }


viewTitle : List (Ui.Attribute msg) -> String -> Ui.Element msg
viewTitle attrs title =
    Ui.el
        (Font.color theme.patchRelease
            :: Font.size theme.font.size.m
            :: Ui.centerX
            :: attrs
        )
        (Ui.text title)


viewFooter : Time.Zone -> Time.Posix -> Ui.Element msg
viewFooter tz now =
    Ui.el
        [ Ui.centerX
        , Ui.padding theme.space.s
        , Font.color theme.patchRelease
        , Font.size theme.font.size.xxs
        ]
        (Ui.text ("dmy©" ++ String.fromInt (Time.toYear tz now)))


viewPage : Model -> Ui.Element Msg
viewPage model =
    case model.page of
        Rss _ feed ->
            Keyed.column
                [ Ui.spacing theme.space.m
                , Ui.width Ui.fill
                , Ui.paddingEach { edges | bottom = theme.space.xxl }
                ]
                (( "feedTitle"
                 , Ui.row
                    [ Ui.width Ui.fill
                    , Ui.height (Ui.shrink |> Ui.minimum 21)
                    , Ui.spacing theme.space.l
                    ]
                    [ viewFeedTitle feed.title
                    , Ui.el [ Ui.width (Ui.px 54), Ui.height (Ui.px 21) ]
                        (viewSpinnerOrRssFeed model.url model.page)
                    ]
                 )
                    :: List.map (viewPackage model) feed.packages
                )

        Help ->
            Help.view

        Error ->
            Ui.paragraph
                [ Font.size theme.font.size.m
                , Font.color theme.dark
                , Font.semiBold
                , Ui.padding theme.space.m
                ]
                [ Ui.text "Service unavailable, please retry later or report the issue on "
                , Ui.link
                    [ Font.color theme.link
                    , Ui.mouseOver [ Font.color theme.overLink ]
                    ]
                    { url = "https://github.com/dmy/elm-greenwood/issues"
                    , label = Ui.text "github"
                    }
                , Ui.text "."
                ]


viewFeedTitle : String -> Ui.Element msg
viewFeedTitle title =
    Ui.el
        [ Ui.width Ui.fill
        , Font.size theme.font.size.m
        , Font.color theme.dark
        , Font.semiBold
        ]
        (Ui.paragraph [] [ Ui.text title ])


viewSpinnerOrRssFeed : Url -> Page -> Ui.Element msg
viewSpinnerOrRssFeed url page =
    case page of
        Rss Loading _ ->
            viewSpinner

        _ ->
            rssFeedLink url


viewSpinner : Ui.Element msg
viewSpinner =
    Ui.html <|
        Html.div [ class "block-list" ] <|
            [ Html.div [ class "spinner" ]
                [ Html.div [ class "bounce1" ] []
                , Html.div [ class "bounce2" ] []
                , Html.div [ class "bounce3" ] []
                ]
            ]


rssFeedLink : Url -> Ui.Element msg
rssFeedLink url =
    Ui.link
        [ Ui.alignRight
        , Font.color theme.link
        , Ui.htmlAttribute (title "RSS feed")
        , Ui.mouseOver
            [ Font.color theme.overLink ]
        ]
        { url = Url.toString (rssFeed url)
        , label = Icon.rssFeed 24
        }


viewPackage : Model -> Package -> ( String, Ui.Element Msg )
viewPackage model pkg =
    let
        id =
            Package.id pkg

        unfolded =
            Set.member id model.unfolded
    in
    Tuple.pair id <|
        Ui.column
            [ Ui.width Ui.fill
            , Ui.inFront (Lazy.lazy viewTag pkg)
            ]
            [ Lazy.lazy3 viewTime model.tz model.now pkg
            , Ui.column
                [ Ui.width Ui.fill
                , Border.shadow theme.shadow
                , transition "box-shadow"
                , Ui.mouseOver [ Border.shadow theme.shadowOver ]
                , attrIf (not unfolded) <|
                    \_ -> Ui.pointer
                , attrIf (not unfolded) <|
                    \_ -> Events.onClick (PackageClicked id)
                ]
                [ Lazy.lazy2 viewPackageHeader pkg unfolded
                , Lazy.lazy2 viewContent pkg unfolded
                ]
            ]


attrIf : Bool -> (() -> Ui.Attribute msg) -> Ui.Attribute msg
attrIf cond toAttr =
    if cond then
        toAttr ()

    else
        nothing


viewIf : Bool -> (() -> Ui.Element msg) -> Ui.Element msg
viewIf cond toElm =
    if cond then
        toElm ()

    else
        Ui.none


nothing : Ui.Attribute msg
nothing =
    Ui.htmlAttribute (Html.Attributes.property "" Json.Encode.null)


transition : String -> Ui.Attribute msg
transition property =
    style "transition" (property ++ " 150ms ease")


style : String -> String -> Ui.Attribute msg
style property value =
    Ui.htmlAttribute <|
        Html.Attributes.style property value


viewTime : Time.Zone -> Time.Posix -> Package -> Ui.Element msg
viewTime tz now pkg =
    Ui.el
        [ Ui.alignRight
        , Ui.paddingXY theme.space.m theme.space.s
        , Font.size theme.font.size.s
        , Font.color theme.dark
        ]
        (Ui.text (Package.time tz now pkg))


viewPackageHeader : Package -> Bool -> Ui.Element Msg
viewPackageHeader pkg unfolded =
    Ui.column
        [ Ui.width Ui.fill
        , if unfolded then
            Ui.paddingXY theme.space.m theme.space.l

          else
            Ui.padding theme.space.m
        , Ui.spacing theme.space.m
        , Background.color (backgroundColor pkg)
        , Font.color (headerColor pkg)
        , attrIf unfolded <|
            \_ -> Ui.inFront viewFoldArrow
        , attrIf unfolded <|
            \_ -> Ui.pointer
        , attrIf unfolded <|
            \_ -> Events.onClick (PackageClicked <| Package.id pkg)
        ]
        [ Ui.wrappedRow
            [ Ui.spacing theme.space.l
            , Ui.width Ui.fill
            , Font.size theme.font.size.m
            , headerFontWeight pkg
            ]
            [ viewName pkg
            , viewVersion pkg
            ]
        ]


viewFoldArrow : Ui.Element msg
viewFoldArrow =
    Ui.el [ Ui.alignBottom, Ui.centerX, Ui.moveDown 1 ] Icon.foldArrow


viewContent : Package -> Bool -> Ui.Element Msg
viewContent pkg unfolded =
    Ui.column
        [ Ui.width Ui.fill
        , Background.color theme.white
        , Font.color theme.dark
        , Ui.padding theme.space.m
        , Ui.spacing theme.space.l
        , Font.size theme.font.size.m
        ]
        [ viewDescription pkg unfolded
        , viewIf unfolded <|
            \_ -> viewDetails pkg
        , Ui.wrappedRow
            [ Ui.spacing theme.space.l
            , Ui.width Ui.fill
            , Font.size theme.font.size.xs
            , Font.color theme.black
            ]
            [ Ui.el [ Ui.width Ui.fill ]
                (Ui.text pkg.elmVersion)
            , viewLicense pkg unfolded
            ]
        ]


viewLicense : Package -> Bool -> Ui.Element msg
viewLicense pkg unfolded =
    if unfolded then
        Ui.link
            [ Font.color theme.link
            , Ui.mouseOver
                [ Font.color theme.overLink ]
            ]
            { url = "https://spdx.org/licenses/" ++ pkg.license
            , label = Ui.text pkg.license
            }

    else
        Ui.el [] (Ui.text pkg.license)


viewDescription : Package -> Bool -> Ui.Element msg
viewDescription pkg unfolded =
    Ui.row
        [ Ui.width Ui.fill
        , Ui.spacing theme.space.m
        ]
        [ Ui.paragraph
            [ Ui.alignTop
            , Ui.spacing theme.space.s
            ]
            [ Ui.text pkg.description
            ]
        , viewImage pkg unfolded
        ]


viewImage : Package -> Bool -> Ui.Element msg
viewImage pkg unfolded =
    let
        img =
            Ui.image
                [ Ui.width (Ui.px 32)
                , Ui.height (Ui.px 32)
                , Ui.alignTop
                , Font.color (Ui.rgba 0 0 0 0)
                ]
                { src = Package.image pkg
                , description = pkg.author
                }
    in
    if unfolded then
        Ui.link
            [ Ui.htmlAttribute (title (pkg.author ++ " last releases"))
            ]
            { url = "/last?" ++ pkg.author ++ "=*"
            , label = img
            }

    else
        Ui.el [] img


viewName : Package -> Ui.Element msg
viewName pkg =
    Ui.paragraph [ Ui.width Ui.fill ]
        [ Ui.text <| pkg.author ++ "/" ++ pkg.name ]


viewVersion : Package -> Ui.Element msg
viewVersion pkg =
    Ui.text pkg.version


viewTag : Package -> Ui.Element msg
viewTag pkg =
    Ui.el
        [ Ui.height (Ui.px theme.space.l)
        , Ui.clip
        , Ui.moveDown (toFloat theme.space.m)
        , Ui.alignTop
        , Ui.paddingXY theme.space.s 0
        ]
        (Ui.el
            [ Font.color (Ui.rgba 1 1 1 0.5)
            , Border.rounded 8
            , Ui.height (Ui.px 48)
            , Background.color (backgroundColor pkg)
            , Ui.paddingXY theme.space.s theme.space.xs
            , Font.size theme.font.size.xxs
            , Font.semiBold
            , Border.shadow theme.shadow
            ]
            (Ui.text (Package.releaseTag pkg.release))
        )


viewDetails : Package -> Ui.Element Msg
viewDetails pkg =
    Ui.column
        [ Ui.width Ui.fill
        , Ui.spacing theme.space.l
        , style "cursor" "auto"
        ]
        [ Ui.wrappedRow
            [ Ui.width Ui.fill
            , Ui.spacing theme.space.l
            ]
            [ link
                { url = Package.github pkg
                , label = "Source"
                , image = linkImage { url = "/github.png", label = "GitHub" }
                }
            , link
                { url = Package.releases pkg
                , label = "Releases"
                , image = Ui.el [ Ui.width (Ui.px 32) ] (Icon.logo 32)
                }
            , link
                { url = Package.doc pkg
                , label = "Documentation"
                , image = linkImage { url = "/elm.png", label = "Elm Packages" }
                }
            ]
        , viewInstall pkg
        , viewIf (not (List.isEmpty pkg.dependencies)) <|
            \_ -> viewDependencies pkg
        ]


link :
    { url : String
    , label : String
    , image : Ui.Element msg
    }
    -> Ui.Element msg
link config =
    Ui.link
        [ Font.color theme.link
        , Ui.mouseOver [ Font.color theme.overLink ]
        ]
        { url = config.url
        , label =
            Ui.row [ Ui.spacing theme.space.m ]
                [ config.image
                , Ui.text config.label
                ]
        }


linkImage : { url : String, label : String } -> Ui.Element msg
linkImage config =
    Ui.image
        [ Ui.width (Ui.px 32)
        , Ui.height (Ui.px 32)
        ]
        { src = config.url
        , description = config.label
        }


viewInstall : Package -> Ui.Element Msg
viewInstall pkg =
    Ui.column
        [ Ui.width Ui.fill
        , Ui.spacing theme.space.s
        ]
        [ Ui.el [ Font.semiBold ] (Ui.text "Install:")
        , Ui.row
            [ Ui.width Ui.fill
            , Ui.spacing theme.space.l
            , Font.size theme.font.size.s
            , Background.color theme.background
            , Font.family
                [ Font.typeface "Source Code Pro"
                , Font.monospace
                ]
            ]
            [ Ui.el [ Ui.width Ui.fill, Ui.scrollbarX ] <|
                Ui.html <|
                    Html.pre [ Html.Attributes.id (Package.id pkg) ]
                        [ Html.text (Package.install pkg) ]
            , Ui.el
                [ Font.color theme.dark
                , Ui.width (Ui.px theme.space.xl)
                ]
                (Ui.el [ Ui.alignRight, Ui.centerY ]
                    (copyToClipboardButton pkg)
                )
            ]
        ]


copyToClipboardButton : Package -> Ui.Element Msg
copyToClipboardButton pkg =
    Input.button
        [ Ui.pointer
        , Ui.mouseDown [ Font.color theme.overLink ]
        , Ui.htmlAttribute (title "Copy to clipboard")
        , Ui.htmlAttribute (class "copy-button")
        , Ui.htmlAttribute <| attribute "data-clipboard-text" (Package.install pkg)
        ]
        { onPress = Nothing
        , label = Icon.copyToClipboard
        }


viewDependencies : Package -> Ui.Element msg
viewDependencies pkg =
    Ui.column [ Ui.spacing theme.space.s ] <|
        Ui.el
            [ Font.semiBold
            , Ui.paddingEach { edges | bottom = theme.space.s }
            ]
            (Ui.text "Dependencies:")
            :: List.map viewDependency (List.sort pkg.dependencies)


viewDependency : String -> Ui.Element msg
viewDependency dep =
    case String.split " " dep of
        name :: constraint ->
            Ui.column
                [ Font.size theme.font.size.xs
                , Ui.spacing theme.space.s
                ]
                [ Ui.link
                    [ Font.color theme.link
                    , Ui.mouseOver [ Font.color theme.overLink ]
                    ]
                    { url = "/?" ++ String.replace "/" "=" name
                    , label = Ui.text name
                    }
                , Ui.el [ Ui.paddingXY theme.space.s 0 ]
                    (Ui.text <| String.join " " constraint)
                ]

        _ ->
            Ui.text dep



-- VIEW HELPERS


edges : { top : Int, right : Int, bottom : Int, left : Int }
edges =
    { top = 0
    , right = 0
    , bottom = 0
    , left = 0
    }


headerFontWeight : Package -> Ui.Attribute msg
headerFontWeight pkg =
    case pkg.release of
        Package.Patch ->
            Font.regular

        _ ->
            Font.semiBold


headerColor : Package -> Ui.Color
headerColor pkg =
    case pkg.release of
        Package.Patch ->
            theme.white

        _ ->
            theme.black


backgroundColor : Package -> Ui.Color
backgroundColor pkg =
    case pkg.release of
        Package.New ->
            theme.newRelease

        Package.Major ->
            theme.majorRelease

        Package.Minor ->
            theme.minorRelease

        Package.Patch ->
            theme.patchRelease



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PackageClicked id ->
            ( { model | unfolded = toggle id model.unfolded }, Cmd.none )

        RssUpdated (Ok feed) ->
            ( { model | page = Rss Loaded feed }, Cmd.none )

        RssUpdated (Err errors) ->
            ( { model | page = Error }, Cmd.none )

        SearchInputChanged input ->
            ( { model | search = input }, Cmd.none )

        SearchRequested ->
            ( model, Nav.pushUrl model.navKey ("/last?_search=" ++ model.search) )

        UpdateRequested now ->
            ( { model | now = now }, getRss model.url )

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    if String.endsWith ".rss" url.path then
                        ( model, Nav.load (Url.toString url) )

                    else
                        ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model
                | page = getPage url model.page
                , url = url
                , search = getSearchQuery url
              }
            , getRss url
            )

        WindowResized width height ->
            ( { model | width = width }, Cmd.none )


toggle : String -> Set String -> Set String
toggle id set =
    if Set.member id set then
        Set.remove id set

    else
        Set.insert id set



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (5 * 60 * 1000) UpdateRequested
        , Browser.Events.onResize WindowResized
        ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
