table! {
    packages (id) {
        id -> Integer,
        timestamp -> BigInt,
        major -> Integer,
        minor -> Integer,
        patch -> Integer,
        author -> Text,
        name -> Text,
        summary -> Text,
        license -> Text,
        elm_version -> Text,
        dependencies -> Text,
        format -> Integer,
    }
}
