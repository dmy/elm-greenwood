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
    (1540223747,
     1, 0, 0,
     'alex-tan', 'loadable',
     'Separate the loading of your application from the logic.',
     'MIT',
     '0.19.0 <= v < 0.20.0',
     '{"elm/browser":"1.0.0 <= v < 2.0.0","elm/core":"1.0.0 <= v < 2.0.0","elm/html":"1.0.0 <= v < 2.0.0"}',
     19
    );
