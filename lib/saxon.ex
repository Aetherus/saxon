defmodule Saxon do
  @moduledoc """
  `Saxon` is a highly opinionated XML request parser for `Plug`.
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

  Note the timestamps in the XML must be in `ISO 8601` format **with timezone**.

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
              "photo" => %Plug.Upload{filename: "cool.png", content_type: "image/png"}
            }
          ]
        }
      }
  """

  @behaviour Plug.Parsers

  alias Saxon.{Sax, Reducer}

  def parse(conn, supertype, subtype, headers, opts \\ [])

  def parse(conn, "application", "vnd.saxon+xml", _headers, opts) do
    {result, conn} = Sax.start(conn, Reducer, chunk_size: opts[:saxon_chunk_size])
    {:ok, result, conn}
  end

  def parse(conn, _, _, _, _) do
    {:next, conn}
  end

end
