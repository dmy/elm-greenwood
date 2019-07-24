module Xml.Decode exposing
    ( Decoder, Errors, Error(..), Xml
    , decodeString, decodeXml, parser
    , bool, float, int
    , attribute, element, elements, path
    , maybe, maybeWithDefault
    , map, map2, map3, map4, map5
    , from
    , xml, succeed, fail
    , andThen, string
    )

{-|

@docs Decoder, Errors, Error, Xml
@docs decodeString, decodeXml, parser
@docs bool, float, int
@docs attribute, element, elements, path
@docs maybe, maybeWithDefault
@docs map, map2, map3, map4, map5
@docs from
@docs xml, succeed, fail

-}

import Document as Doc
import Internal
import Parser exposing ((|.), (|=), Parser)


type Xml
    = Xml Doc.Xml


type Decoder a
    = Decoder (Xml -> Result Errors a)


type alias Errors =
    List Error


type Error
    = ParseError Parser.DeadEnd
    | ExpectingString
    | ExpectingInt
    | ExpectingBool
    | ExpectingSingleElement String
    | NotFound String
    | Error String


decodeString : Decoder a -> String -> Result Errors a
decodeString decoder str =
    Parser.run
        (Parser.succeed identity
            |= parser
            |. Parser.end
        )
        str
        |> Result.mapError (List.map ParseError)
        |> Result.andThen (decodeXml decoder)


decodeXml : Decoder a -> Xml -> Result Errors a
decodeXml (Decoder decode) x =
    decode x


parser : Parser Xml
parser =
    Parser.map Xml Internal.parser



-- PRIMITIVES


int : Decoder Int
int =
    Decoder (stringHelp >> Result.andThen intHelp)


intHelp : String -> Result Errors Int
intHelp str =
    case String.toInt str of
        Just i ->
            Ok i

        Nothing ->
            Err [ ExpectingInt ]


float : Decoder Float
float =
    Decoder (stringHelp >> Result.andThen floatHelp)


floatHelp : String -> Result Errors Float
floatHelp str =
    case String.toFloat str of
        Just n ->
            Ok n

        Nothing ->
            Err [ ExpectingInt ]


bool : Decoder Bool
bool =
    Decoder (stringHelp >> Result.andThen boolHelp)


boolHelp : String -> Result Errors Bool
boolHelp str =
    case str of
        "True" ->
            Ok True

        "False" ->
            Ok False

        "true" ->
            Ok True

        "false" ->
            Ok False

        "1" ->
            Ok True

        "0" ->
            Ok False

        _ ->
            Err [ ExpectingBool ]


string : Decoder String
string =
    Decoder stringHelp


stringHelp : Xml -> Result Errors String
stringHelp (Xml x) =
    case x of
        Doc.Text str ->
            Ok str

        Doc.Element _ _ [ Doc.Text str ] ->
            Ok str

        Doc.Element _ _ [] ->
            Ok ""

        _ ->
            Err [ ExpectingString ]



-- ELEMENT PRIMITIVES


attribute : String -> Decoder a -> Decoder a
attribute name decoder =
    Decoder (attributeHelp name decoder)


attributeHelp : String -> Decoder a -> Xml -> Result Errors a
attributeHelp name (Decoder decoder) (Xml x) =
    case Doc.attribute name x of
        Just attrValue ->
            decoder (Xml (Doc.Text attrValue))

        Nothing ->
            Err [ NotFound name ]


element : String -> Decoder a -> Decoder a
element name decoder =
    Decoder (elementHelp name decoder)


elementHelp : String -> Decoder a -> Xml -> Result Errors a
elementHelp name decoder (Xml x) =
    case Doc.elements name x of
        [ elm ] ->
            decodeXml decoder (Xml elm)

        _ :: _ ->
            Err [ ExpectingSingleElement name ]

        [] ->
            Err [ NotFound name ]


elements : String -> Decoder a -> Decoder (List a)
elements name decoder =
    Decoder (elementsHelp name decoder)


elementsHelp : String -> Decoder a -> Xml -> Result Errors (List a)
elementsHelp name decoder (Xml x) =
    let
        results =
            Doc.elements name x
                |> List.map Xml
                |> List.map (decodeXml decoder)
    in
    case errors results of
        [] ->
            results
                |> List.map Result.toMaybe
                |> List.filterMap identity
                |> Ok

        errs ->
            Err errs


errors : List (Result Errors a) -> List Error
errors results =
    List.filterMap errorsHelp results
        |> List.concat


errorsHelp : Result Errors a -> Maybe Errors
errorsHelp result =
    case result of
        Err resultErrors ->
            Just resultErrors

        Ok _ ->
            Nothing


path : List String -> Decoder a -> Decoder a
path elms decoder =
    Decoder (pathHelp elms decoder)


pathHelp : List String -> Decoder a -> Xml -> Result Errors a
pathHelp elms ((Decoder dec) as decoder) x =
    case elms of
        name :: names ->
            case elementHelp name xml x of
                Ok subXml ->
                    pathHelp names decoder subXml

                Err errs ->
                    Err errs

        [] ->
            dec x



-- INCONSISTENT STRUCTURE


maybe : Decoder a -> Decoder (Maybe a)
maybe decoder =
    Decoder (maybeHelp decoder)


maybeHelp : Decoder a -> Xml -> Result Errors (Maybe a)
maybeHelp decoder x =
    case decodeXml decoder x of
        Ok a ->
            Ok (Just a)

        Err [ NotFound _ ] ->
            Ok Nothing

        Err errs ->
            Err errs


maybeWithDefault : a -> Decoder a -> Decoder a
maybeWithDefault default decoder =
    Decoder (maybeWithDefaultHelp default decoder)


maybeWithDefaultHelp : a -> Decoder a -> Xml -> Result Errors a
maybeWithDefaultHelp default decoder x =
    case decodeXml decoder x of
        Ok a ->
            Ok a

        Err [ NotFound _ ] ->
            Ok default

        Err errs ->
            Err errs



-- MAPPING


map : (a -> b) -> Decoder a -> Decoder b
map f (Decoder decoder) =
    Decoder (\x -> x |> decoder |> Result.map f)


map2 : (a -> b -> c) -> Decoder a -> Decoder b -> Decoder c
map2 f (Decoder decoderA) (Decoder decoderB) =
    Decoder (\x -> Result.map2 f (decoderA x) (decoderB x))


map3 :
    (a -> b -> c -> d)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
map3 f (Decoder decoderA) (Decoder decoderB) (Decoder decoderC) =
    Decoder (\x -> Result.map3 f (decoderA x) (decoderB x) (decoderC x))


map4 :
    (a -> b -> c -> d -> e)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
map4 f (Decoder decA) (Decoder decB) (Decoder decC) (Decoder decD) =
    Decoder (\x -> Result.map4 f (decA x) (decB x) (decC x) (decD x))


map5 :
    (a -> b -> c -> d -> e -> f)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
map5 f (Decoder decA) (Decoder decB) (Decoder decC) (Decoder decD) (Decoder decE) =
    Decoder (\x -> Result.map5 f (decA x) (decB x) (decC x) (decD x) (decE x))



-- PIPELINE


from : Decoder a -> Decoder (a -> b) -> Decoder b
from =
    map2 (|>)



-- FANCY DECODING


xml : Decoder Xml
xml =
    Decoder (\x -> Ok x)


succeed : a -> Decoder a
succeed a =
    Decoder (\_ -> Ok a)


fail : String -> Decoder a
fail err =
    Decoder (\_ -> Err [ Error err ])


andThen : (a -> Decoder b) -> Decoder a -> Decoder b
andThen thenDecoder decoder =
    Decoder (andThenHelp thenDecoder decoder)


andThenHelp : (a -> Decoder b) -> Decoder a -> Xml -> Result Errors b
andThenHelp toDecoderB (Decoder decoderA) x =
    case decoderA x of
        Ok a ->
            let
                (Decoder decoderB) =
                    toDecoderB a
            in
            decoderB x

        Err errs ->
            Err errs
