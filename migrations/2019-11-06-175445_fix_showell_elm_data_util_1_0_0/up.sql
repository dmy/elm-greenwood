-- This package is not accepted by greenwood because 
-- it has two "elm-version" fields
INSERT INTO packages
    (timestamp,
     major, minor, patch,
     author, name,
     summary,
     license,
     elm_version,
     dependencies,
     format
    )
VALUES
    (1573059885,
     1, 0, 0,
     'showell', 'elm-data-util',
     'parse JSON',
     'MIT',
     '0.19.0 <= v < 0.20.0',
     '{"elm/browser":"1.0.2 <= v < 2.0.0","elm/core":"1.0.2 <= v < 2.0.0","elm/html":"1.0.0 <= v < 2.0.0","elm/parser": "1.1.0 <= v < 2.0.0"}',
     19
    );
