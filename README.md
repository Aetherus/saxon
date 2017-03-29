# Saxon (not released yet!)

Saxon is a highly opinionated XML request parser for `Plug`.
It only supports parsing the HTTP requests whose `Content-Type` is `application/vnd.saxon+xml`.

The content type that `Saxon` handles is `application/vnd.saxon+xml`.
Base64 encoded files can be embedded in the XML at any level.
For flat request bodies with file upload, `multipart/form-data` is good.
For hierarchical request bodies without embedded files, you should stick to `application/json`.

    <map>
      <map name="article">
        <string name="title">Elixir Rocks</string>
        <integer name="author_id">1</integer>
        <timestamp name="published_at">2017-03-29T10:23:35Z</timestamp>
        <boolean name="private">false</boolean>
        <file name="logo" filename="logo.png" content-type="image/png">
          (Base64 encoded file content here)
        </file>
        <list name="sections">
          <map>
            <string name="content">Elixir really rocks.</string>
            <file name="photo" filename="awesome.jpg" content-type="image/jpeg">
              (Base64 encoded file content here)
            </file>
          </map>
          <map>
            <string name="content">Lorem ipsum ...</string>
            <file name="photo" filename="cool.png" content-type="image/png">
              (Base64 encoded file content here)
            </file>
          </map>
        </list>
      </map>
    </map>

The parser parses such XML and yields

    %{
      "article" => %{
        "title" => "Elixir Rocks",
        "author_id" => 1,
        "published_at" => %DateTime{year: 2017, month: 3, day: 29, hour: 10, minute: 23, second: 35, time_zone: "Etc/UTC", ...},
        "private" => false,
        "logo" => %Plug.Upload{filename: "logo.png", content_type: "image/png", ...},
        "sections" => [
          %{
            "content" => "Elixir really rocks.",
            "photo" => %Plug.Upload{filename: "awesome.jpg", content_type: "image/jpeg", ...}
          },
          %{
            "content" => "Lorem ipsum ...",
            "photo" => %Plug.Conn{filename: "cool.png" content_type: "image/png"}
          }
        ]
      }
    }
    
Currently supported XML elements:

*  `string`
*  `integer`
*  `float`
*  `boolean`
*  `timestamp`, the format of which must be ISO 8601. Timezone is required.
*  `file`, allows attributes `filename` and `content-type`.
*  `list`
*  `map`, all the child elements of which must have a unique `name` attribute.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `saxon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:saxon, "~> 0.1.0"}]
end
```

_NOT AVAILABLE ON HEX YET!_

## How to use

Just add `Saxon` to the parsers. 
Note that if you have a general XML parser in your parser chain, be sure to add `Saxon` *before* that parser.

    plug Parsers, 
      parsers: [Saxon, :urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/saxon](https://hexdocs.pm/saxon).

