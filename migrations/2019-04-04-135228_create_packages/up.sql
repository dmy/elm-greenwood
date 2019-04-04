CREATE TABLE packages (
    id INTEGER PRIMARY KEY NOT NULL,
    timestamp INTEGER NOT NULL,
    major INTEGER NOT NULL,
    minor INTEGER NOT NULL,
    patch INTEGER NOT NULL,
    author TEXT NOT NULL,
    name TEXT NOT NULL,
    summary TEXT NOT NULL,
    license TEXT NOT NULL,
    elm_version TEXT NOT NULL,
    dependencies TEXT NOT NULL
)
