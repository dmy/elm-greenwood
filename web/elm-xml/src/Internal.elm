module Internal exposing (parser)

import Document exposing (Attribute(..), Xml(..))
import Parser
    exposing
        ( (|.)
        , (|=)
        , Parser
        , Step
        , andThen
        , chompIf
        , chompUntil
        , chompWhile
        , getChompedString
        , getOffset
        , loop
        , map
        , oneOf
        , succeed
        , symbol
        , token
        , variable
        )
import Set



-- PARSER


parser : Parser Xml
parser =
    succeed Xml
        |. whitespace
        |= oneOf
            [ succeed identity
                |. oneOf
                    [ symbol "<?xml "
                    , symbol "<?xml\t"
                    , symbol "<?xml\n"
                    , symbol "<?xml\u{000D}"
                    ]
                |. whitespace
                |= zeroOrMore attribute
                |. whitespace
                |. symbol "?>"
                |. misc
                |. docTypeDecl
                |. whitespace
            , succeed []
            ]
        |= element



-- SPACES


isSpace : Char -> Bool
isSpace c =
    c == ' ' || c == '\u{000D}' || c == '\n' || c == '\t'


whitespace : Parser ()
whitespace =
    chompWhile isSpace



-- UTILS


zeroOrMore : Parser a -> Parser (List a)
zeroOrMore item =
    loop [] (zeroOrMoreHelp item)


zeroOrMoreHelp : Parser a -> List a -> Parser (Parser.Step (List a) (List a))
zeroOrMoreHelp item revItems =
    oneOf
        [ succeed (\a -> Parser.Loop (a :: revItems))
            |= item
        , succeed ()
            |> map (\_ -> Parser.Done (List.reverse revItems))
        ]



-- COMMENTS


comment : Parser Xml
comment =
    succeed Comment
        |. symbol "<!--"
        |= getChompedString (chompUntil "-->")
        |. symbol "-->"



-- MISC


misc : Parser ()
misc =
    -- TODO: PI
    loop 0 <|
        ifProgress <|
            oneOf
                [ map (always ()) comment
                , whitespace
                , map (always ()) processingInstruction
                ]


ifProgress : Parser a -> Int -> Parser (Parser.Step Int ())
ifProgress parser_ offset =
    succeed identity
        |. parser_
        |= getOffset
        |> map
            (\newOffset ->
                if offset == newOffset then
                    Parser.Done ()

                else
                    Parser.Loop newOffset
            )



-- PROCESSING INSTRUCTIONS


processingInstruction : Parser Xml
processingInstruction =
    succeed PI
        |. symbol "<?"
        |= name
        |. whitespace
        |= getChompedString (chompUntil "?>")
        |. whitespace
        |. symbol "?>"


isChar : Char -> Bool
isChar c =
    let
        code =
            Char.toCode c
    in
    (code == 0x09)
        || (code == 0x0A)
        || (code == 0x0D)
        || (code >= 0x20 && code <= 0xD7FF)
        || (code >= 0xE000 && code <= 0xFFFD)
        || (code >= 0x00010000 && code <= 0x0010FFFF)



-- DOCTYPE


docTypeDecl : Parser ()
docTypeDecl =
    succeed ()



-- ATTRIBUTE


attribute : Parser Attribute
attribute =
    succeed Attribute
        |= name
        |. whitespace
        |. symbol "="
        |. whitespace
        |= oneOf
            [ doubleQuotedString
            , quotedString
            ]
        |. whitespace


knownAttribute : String -> Parser String
knownAttribute name_ =
    succeed identity
        |. token name_
        |. whitespace
        |. symbol "="
        |. whitespace
        |= oneOf
            [ quotedString
            , doubleQuotedString
            ]



-- QUOTED STRINGS


quotedString : Parser String
quotedString =
    succeed identity
        |. symbol "'"
        |= getChompedString (chompUntil "'")
        |. symbol "'"


doubleQuotedString : Parser String
doubleQuotedString =
    succeed identity
        |. symbol "\""
        |= getChompedString (chompUntil "\"")
        |. symbol "\""



-- ELEMENT


element : Parser Xml
element =
    succeed Tuple.pair
        |. symbol "<"
        |= name
        |. whitespace
        |= zeroOrMore attribute
        |. whitespace
        |> andThen content


content : ( String, List Attribute ) -> Parser Xml
content ( elmName, attrs ) =
    succeed identity
        |= oneOf
            [ succeed (Element elmName attrs [])
                |. symbol "/>"
            , succeed (Element elmName attrs)
                |. symbol ">"
                |. whitespace
                |= loop [] (children elmName)
            ]
        |. whitespace


children : String -> List Xml -> Parser (Step (List Xml) (List Xml))
children parentName revElms =
    oneOf
        [ succeed (Parser.Done <| List.reverse revElms)
            |. endTag parentName
        , succeed (\txt -> Parser.Loop (txt :: revElms))
            |= oneOf
                [ charData
                , cdata
                ]
        , succeed (\c -> Parser.Loop (c :: revElms))
            |= comment
        , succeed (\pi -> Parser.Loop (pi :: revElms))
            |= processingInstruction
        , succeed (\elm -> Parser.Loop (elm :: revElms))
            |= element
        ]


charData : Parser Xml
charData =
    map Text <|
        getChompedString <|
            succeed ()
                |. chompIf (\c -> c /= '<')
                |. chompUntil "<"


cdata : Parser Xml
cdata =
    succeed Text
        |. symbol "<![CDATA["
        |= getChompedString (chompUntil "]]>")
        |. symbol "]]>"
        |. whitespace


endTag : String -> Parser ()
endTag name_ =
    succeed ()
        |. symbol "</"
        |. whitespace
        |. token name_
        |. whitespace
        |. symbol ">"


name : Parser String
name =
    variable
        { start = isNameStartChar
        , inner = isNameChar
        , reserved = Set.empty
        }


isNameStartChar : Char -> Bool
isNameStartChar c =
    let
        code =
            Char.toCode c
    in
    (c == ':')
        || (c == '_')
        || Char.isAlpha c
        || (code >= 0xC0 && code <= 0xD6)
        || (code >= 0xD8 && code <= 0xF6)
        || (code >= 0xF8 && code <= 0x02FF)
        || (code >= 0x0370 && code <= 0x037D)
        || (code >= 0x037F && code <= 0x1FFF)
        || (code >= 0x200C && code <= 0x200D)
        || (code >= 0x2070 && code <= 0x218F)
        || (code >= 0x2C00 && code <= 0x2FEF)
        || (code >= 0x3001 && code <= 0xD7FF)
        || (code >= 0xF900 && code <= 0xFDCF)
        || (code >= 0xFDF0 && code <= 0xFFFD)
        || (code >= 0x00010000 && code <= 0x000EFFFF)


isNameChar : Char -> Bool
isNameChar c =
    let
        code =
            Char.toCode c
    in
    isNameStartChar c
        || (c == '-')
        || (c == '.')
        || Char.isDigit c
        || (code == 0xB7)
        || (code >= 0x0300 && code <= 0x036F)
        || (code >= 0x203F && code <= 0x2040)
