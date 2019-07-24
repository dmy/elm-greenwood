module Theme exposing (theme)

import Element as Ui
import Element.Font as Font


type alias Shadow =
    { offset : ( Float, Float )
    , size : Float
    , blur : Float
    , color : Ui.Color
    }


theme :
    { font :
        { family : List Font.Font
        , size :
            { xxs : Int
            , xs : Int
            , s : Int
            , m : Int
            , l : Int
            , xl : Int
            , xxl : Int
            }
        }
    , background : Ui.Color
    , black : Ui.Color
    , white : Ui.Color
    , dark : Ui.Color
    , searchBox : Ui.Color
    , newRelease : Ui.Color
    , majorRelease : Ui.Color
    , minorRelease : Ui.Color
    , patchRelease : Ui.Color
    , link : Ui.Color
    , overLink : Ui.Color
    , shadow : Shadow
    , shadowOver : Shadow
    , space :
        { xs : Int
        , s : Int
        , m : Int
        , l : Int
        , xl : Int
        , xxl : Int
        }
    }
theme =
    { font =
        { family =
            [ Font.typeface "Source Sans Pro"
            , Font.typeface "Trebuchet MS"
            , Font.typeface "Lucida Grande"
            , Font.typeface "Bitstream Vera Sans"
            , Font.typeface "Helvetica Neue"
            , Font.sansSerif
            ]
        , size =
            { xxs = 12
            , xs = 13
            , s = 14
            , m = 16
            , l = 17
            , xl = 18
            , xxl = 20
            }
        }
    , background = Ui.rgb 0.98 0.98 0.98
    , black = Ui.rgb 0 0 0
    , white = Ui.rgb 1 1 1
    , dark = Ui.rgb 0.1 0.1 0.1
    , searchBox = Ui.rgb 0.8 0.8 0.8
    , newRelease = Ui.rgb255 127 209 59
    , majorRelease = Ui.rgb255 240 173 0
    , minorRelease = Ui.rgb255 96 181 204
    , patchRelease = Ui.rgb255 90 99 120
    , link = Ui.rgb255 17 132 206
    , overLink = Ui.rgb255 234 21 122
    , shadow =
        { offset = ( 0, 2 )
        , size = 0
        , blur = 2
        , color = Ui.rgb 0.6 0.6 0.6
        }
    , shadowOver =
        { offset = ( 0, 2 )
        , size = 0
        , blur = 8
        , color = Ui.rgb 0.6 0.6 0.6
        }
    , space =
        { xs = 2
        , s = 4
        , m = 8
        , l = 16
        , xl = 32
        , xxl = 64
        }
    }
