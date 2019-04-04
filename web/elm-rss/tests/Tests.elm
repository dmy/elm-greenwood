module Tests exposing (suite)

import Expect exposing (Expectation)
import Rss exposing (Rss)
import Rss.Channel as Channel
import Rss.Item as Item
import Test exposing (..)
import Time exposing (Month(..))


minRss : Result String Rss
minRss =
    Rss.decode """
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
   <channel>
      <title />
      <link />
      <description />
   </channel>
</rss>
"""


fullRss : Result String Rss
fullRss =
    Rss.decode """
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
   <channel>
      <title>title</title>
      <link>https://link.com</link>
      <description>description</description>
      <language>en-us</language>
      <copyright>©</copyright>
      <pubDate>Thu, 01 Jan 70 00:00:00 GMT</pubDate>
      <item>
        <title>title</title>
      </item>
      <item />
   </channel>
</rss>
"""



-- TESTS


suite : Test
suite =
    describe "Rss"
        [ describe "Minimal Rss"
            [ test "version" <|
                \() ->
                    Expect.equal (Result.map Rss.version minRss) (Ok "2.0")
            , describe "Channel"
                [ test "title" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.title) minRss)
                            (Ok "")
                , test "link" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.link) minRss)
                            (Ok "")
                , test "description" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.description) minRss)
                            (Ok "")
                , test "items" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.items) minRss)
                            (Ok [])
                , test "language" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.language) minRss)
                            (Ok Nothing)
                , test "copyright" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.copyright) minRss)
                            (Ok Nothing)
                , test "managingEditor" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.managingEditor) minRss)
                            (Ok Nothing)
                , test "webMaster" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.webMaster) minRss)
                            (Ok Nothing)
                , test "pubDate" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.pubDate) minRss)
                            (Ok Nothing)
                , test "lastBuildDate" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.lastBuildDate) minRss)
                            (Ok Nothing)
                , test "categories" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.categories) minRss)
                            (Ok [])
                , test "generator" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.generator) minRss)
                            (Ok Nothing)
                , test "docs" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.docs) minRss)
                            (Ok Nothing)
                , test "cloud" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.cloud) minRss)
                            (Ok Nothing)
                , test "ttl" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.ttl) minRss)
                            (Ok Nothing)
                , test "image" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.image) minRss)
                            (Ok Nothing)
                , test "rating" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.rating) minRss)
                            (Ok Nothing)
                , test "textInput" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.textInput) minRss)
                            (Ok Nothing)
                , test "skipHours" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.skipHours) minRss)
                            (Ok [])
                , test "skipDays" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.skipDays) minRss)
                            (Ok [])
                ]
            ]
        , describe "Full Rss"
            [ test "version" <|
                \() ->
                    Expect.equal (Result.map Rss.version fullRss) (Ok "2.0")
            , describe "Channel"
                [ test "title" <|
                    \() ->
                        Expect.equal (Result.map (Rss.channel >> Channel.title) fullRss)
                            (Ok "title")
                , test "link" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.link) fullRss)
                            (Ok "https://link.com")
                , test "description" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.description) fullRss)
                            (Ok "description")
                , test "language" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.language) fullRss)
                            (Ok <| Just "en-us")
                , test "copyright" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.copyright) fullRss)
                            (Ok <| Just "©")
                , test "pubDate" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.pubDate) fullRss)
                            (Ok <| Just <| Time.millisToPosix 0)
                ]
            , describe "Items"
                [ test "title" <|
                    \() ->
                        Expect.equal
                            (Result.map (Rss.channel >> Channel.items >> List.map Item.title) fullRss)
                            (Ok [ Just "title", Nothing ])
                ]
            ]
        ]
