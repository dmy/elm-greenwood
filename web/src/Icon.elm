module Icon exposing (copyToClipboard, foldArrow, logo, rssFeed, search)

import Element as Ui
import Svg
import Svg.Attributes as SvgA


copyToClipboard : Ui.Element msg
copyToClipboard =
    Ui.html <|
        Svg.svg [ SvgA.width "24", SvgA.height "24", SvgA.viewBox "0 0 24 24" ]
            [ Svg.path [ SvgA.d "M0 0h24v24H0z", SvgA.fill "none" ] []
            , Svg.path
                [ SvgA.d """m11.667 10.333h1.3333v-1.3333h-1.3333zm0
                  10.667h1.3333v-1.3333h-1.3333zm2.6667 0h1.3333v-1.3333h-1.3333zm-5.3333
                  0h1.3333v-1.3333h-1.3333zm0-2.6667h1.3333v-1.3333h-1.3333zm0-2.6667h1.3333v
                  -1.3333h-1.3333zm0-2.6667h1.3333v-1.3333h-1.3333zm0-2.6667h1.3333v-1.3333h
                  -1.3333zm10.667 8h1.3333v-1.3333h-1.3333zm0-2.6667h1.3333v-1.3333h-1.3333zm0
                  5.3333h1.3333v-1.3333h-1.3333zm0-8h1.3333v-1.3333h-1.3333zm0-4v1.3333h1.3333v-1.3333zm-5.3333
                  1.3333h1.3333v-1.3333h-1.3333zm2.6667 10.667h1.3333v-1.3333h-1.3333zm0-10.667h1.3333v-1.3333h-1.3333z"""
                , SvgA.strokeWidth ".66667"
                , SvgA.fill "currentColor"
                ]
                []
            , Svg.path
                [ SvgA.d """m17.222 2.7778h-3.7156c-0.37333-1.0311-1.3511-1.7778-2.5067-1.7778-1.1556
                  0-2.1333 0.74667-2.5067 1.7778h-3.7156c-0.97778 0-1.7778 0.8-1.7778 1.7778v12.444c0
                  0.97778 0.8 1.7778 1.7778 1.7778h12.444c0.97778 0 1.7778-0.8
                  1.7778-1.7778v-12.444c0-0.97778-0.8-1.7778-1.7778-1.7778zm-6.2222
                  0c0.48889 0 0.88889 0.4 0.88889 0.88889 0 0.48889-0.4 0.88889-0.88889
                  0.88889s-0.88889-0.4-0.88889-0.88889c0-0.48889 0.4-0.88889
                  0.88889-0.88889zm4.4444 12.444h-8.8889v-8.8889h8.8889z"""
                , SvgA.strokeWidth ".88889"
                , SvgA.fill "currentColor"
                ]
                []
            ]


foldArrow : Ui.Element msg
foldArrow =
    Ui.html <|
        Svg.svg
            [ SvgA.viewBox "0 0 100 50"
            , SvgA.height "8"
            ]
            [ polygon "white" "0,50, 100,50 50,0" ]


logo : Int -> Ui.Element msg
logo size =
    Ui.html <|
        Svg.svg
            [ SvgA.width (String.fromInt size)
            , SvgA.height (String.fromInt size)
            , SvgA.viewBox "0 0 200 200"
            ]
            [ Svg.g
                [ SvgA.stroke "#fff", SvgA.strokeWidth "4px" ]
                [ polygon "#7fd13b" "100,0 200,100 100,100"
                , polygon "#7fd13b" "0,100 50,100 50,150"
                , polygon "#7fd13b" "50,100 50,150 100,150"
                , polygon "#60b5cc" "50,100 100,150 150,100"
                , polygon "#7fd13b" "100,150 150,100 200,100 150,150"
                , polygon "#5a6378" "75,150 125,150 125,200 75,200"
                , polygon "#7fd13b" "100,0 100,100 0,100"
                ]
            ]


polygon : String -> String -> Svg.Svg msg
polygon color points =
    Svg.polygon
        [ SvgA.fill color
        , SvgA.points points
        ]
        []


rssFeed : Int -> Ui.Element msg
rssFeed size =
    Ui.html <|
        Svg.svg
            [ SvgA.width (String.fromInt size)
            , SvgA.height (String.fromInt size)
            , SvgA.viewBox "0 0 24 24"
            ]
            [ Svg.path [ SvgA.fill "none", SvgA.d "M0 0h24v24H0z" ] []
            , Svg.circle
                [ SvgA.fill "currentColor"
                , SvgA.cx "6.18"
                , SvgA.cy "17.82"
                , SvgA.r "2.18"
                ]
                []
            , Svg.path
                [ SvgA.fill "currentColor"
                , SvgA.d """M4 4.44v2.83c7.03 0 12.73 5.7 12.73
              12.73h2.83c0-8.59-6.97-15.56-15.56-15.56zm0
              5.66v2.83c3.9 0 7.07 3.17 7.07
              7.07h2.83c0-5.47-4.43-9.9-9.9-9.9z"""
                ]
                []
            ]


search : Ui.Element msg
search =
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
