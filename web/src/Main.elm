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
import Html.Attributes exposing (class)
import Html.Events
import Http
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
    let
        rssUrl =
            if String.endsWith "/" url.path then
                { url | path = url.path ++ ".rss" }

            else
                { url | path = url.path ++ "/.rss" }
    in
    case url.path of
        "/help" ->
            Cmd.none

        _ ->
            Http.get
                { url = Url.toString rssUrl
                , expect = expectRss RssUpdated
                }


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
        [ viewLogo model.width
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
        [ Border.rounded 0
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
        , Ui.inFront searchIcon
        ]
        { onChange = SearchInputChanged
        , text = input
        , placeholder = Nothing
        , label = Input.labelHidden "search"
        }


searchIcon : Ui.Element Msg
searchIcon =
    Ui.el
        [ Ui.paddingXY theme.space.m 0
        , Ui.alignRight
        , Ui.centerY
        , onBlockedClick SearchRequested
        , Ui.pointer
        , Font.color theme.searchBox
        , Ui.mouseDown
            [ Font.color theme.patchRelease ]
        ]
    <|
        Ui.html <|
            Svg.svg [ SvgA.width "24", SvgA.height "24", SvgA.viewBox "0 0 24 24" ]
                [ Svg.path [ SvgA.fill "none", SvgA.d "M0 0h24v24H0V0z" ] []
                , Svg.path
                    [ SvgA.d """M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11
                16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 
                0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6
                0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14
                9.5 14z"""
                    , SvgA.fill "currentColor"
                    ]
                    []
                ]


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


viewLogo : Int -> Ui.Element msg
viewLogo width =
    Ui.link []
        { url = "/"
        , label =
            Ui.column []
                [ if width > 768 then
                    logo 48

                  else
                    logo 60
                , viewIf (width > 768) <|
                    \_ -> viewTitle [] "elm greenwood"
                ]
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


logo : Int -> Ui.Element msg
logo size =
    Ui.el [ Ui.width (Ui.px size), Ui.height (Ui.px size), Ui.moveUp 2, Ui.centerX ] <|
        Ui.html <|
            Svg.svg
                [ SvgA.width (String.fromInt size)
                , SvgA.height (String.fromInt size)
                , SvgA.viewBox "0 0 200 200"
                ]
                [ Svg.g
                    [ SvgA.stroke "#fff", SvgA.strokeWidth "4px" ]
                    [ polygon "#7fd13bff" "100,0 200,100 100,100"
                    , polygon "#7fd13bff" "0,100 50,100 50,150"
                    , polygon "#7fd13bff" "50,100 50,150 100,150"
                    , polygon "#60b5ccff" "50,100 100,150 150,100"
                    , polygon "#7fd13bff" "100,150 150,100 200,100 150,150"
                    , polygon "#5a6378ff" "75,150 125,150 125,200 75,200"
                    , polygon "#7fd13bff" "100,0 100,100 0,100"
                    ]
                ]


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
                        (viewLoader model.page)
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


viewLoader : Page -> Ui.Element msg
viewLoader page =
    case page of
        Rss Loading _ ->
            viewSpinner

        _ ->
            Ui.none


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
    Ui.el [ Ui.alignBottom, Ui.centerX, Ui.moveDown 1 ] <|
        Ui.html <|
            Svg.svg
                [ SvgA.viewBox "0 0 100 50"
                , SvgA.height "8"
                ]
                [ polygon "white" "0,50, 100,50 50,0" ]


polygon : String -> String -> Svg.Svg msg
polygon color points =
    Svg.polygon
        [ SvgA.fill color
        , SvgA.points points
        ]
        []


viewContent : Package -> Bool -> Ui.Element msg
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
        Ui.link []
            { url = "/last?" ++ pkg.author ++ "=*"
            , label = img
            }

    else
        Ui.el [] img


viewName : Package -> Ui.Element msg
viewName pkg =
    Ui.el [ Ui.width Ui.fill ]
        (Ui.text <| pkg.author ++ "/" ++ pkg.name)


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


viewDetails : Package -> Ui.Element msg
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
                , image = logo 32
                }
            , link
                { url = Package.doc pkg
                , label = "Documentation"
                , image = linkImage { url = "/elm.png", label = "Elm Packages" }
                }
            ]
        , viewInstall pkg
        , Ui.column [ Ui.spacing theme.space.s ] <|
            Ui.el
                [ Font.semiBold
                , Ui.paddingEach { edges | bottom = theme.space.s }
                ]
                (Ui.text "Dependencies:")
                :: List.map viewDependency (List.sort pkg.dependencies)
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


viewInstall : Package -> Ui.Element msg
viewInstall pkg =
    Ui.column
        [ Ui.width Ui.fill
        , Ui.spacing theme.space.s
        ]
        [ Ui.el [ Font.semiBold ] (Ui.text "Install:")
        , Ui.el
            [ Ui.width Ui.fill
            , Background.color theme.background
            , Font.size theme.font.size.s
            , Ui.scrollbarX
            , Font.family
                [ Font.typeface "Source Code Pro"
                , Font.monospace
                ]
            ]
            (Ui.html <| Html.pre [] [ Html.text (Package.install pkg) ])
        ]


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


edges :
    { top : Int
    , right : Int
    , bottom : Int
    , left : Int
    }
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
            ( { model | page = getPage url model.page, url = url }
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
