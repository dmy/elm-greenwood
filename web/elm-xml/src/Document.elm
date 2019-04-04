module Document exposing (Attribute(..), Xml(..), attribute, children, elements)


type Xml
    = Xml (List Attribute) Xml
    | Element String (List Attribute) (List Xml)
    | Text String
    | Comment String
    | PI String String


type Attribute
    = Attribute String String



-- HELPERS


attribute : String -> Xml -> Maybe String
attribute name xml =
    attributes xml
        |> List.filter (\(Attribute attrName _) -> attrName == name)
        |> List.map (\(Attribute _ value) -> value)
        |> List.head


attributes : Xml -> List Attribute
attributes xml =
    case xml of
        Xml attrs _ ->
            attrs

        Element _ attrs _ ->
            attrs

        _ ->
            []


children : Xml -> List Xml
children xml =
    case xml of
        Xml _ element ->
            [ element ]

        Element _ _ elementChildren ->
            elementChildren

        _ ->
            []


elements : String -> Xml -> List Xml
elements name xml =
    children xml
        |> List.filter (isElementNamed name)


isElementNamed : String -> Xml -> Bool
isElementNamed name xml =
    case xml of
        Element elementName _ _ ->
            elementName == name

        _ ->
            False
