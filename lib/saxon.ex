defmodule Saxon do
  require IEx
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

  import Plug.Conn
  alias Plug.Parsers.ParseError
  alias Saxon.Parsers

  @parsers %{
    'boolean' => Parsers.BOOLEAN,
    'file' => Parsers.FILE,
    'float' => Parsers.FLOAT,
    'integer' => Parsers.INTEGER,
    'list' => Parsers.LIST,
    'map' => Parsers.MAP,
    'string' => Parsers.STRING,
    'timestamp' => Parsers.TIMESTAMP
  }

  def parse(conn, "application", "vnd.saxon+xml", _headers, _opts) do
    {:ok, params, _} = :xmerl_sax_parser.stream("",
      continuation_state: %{conn: conn, done: false},
      continuation_fun: &read_req_body/1,
      event_state: [],  # the stack
      event_fun: &handle_sax_event/3)
    {:ok, params, conn}
  end

  def parse(conn, _, _, _, _) do
    {:next, conn}
  end

  defp read_req_body(%{conn: conn, done: false}) do
    case read_body(conn) do
      {status, chunk, conn} when status in [:ok, :more] ->
        {chunk, %{conn: conn, done: status == :ok}}
      {:error, reason} -> raise ParseError, reason
    end
  end

  defp read_req_body(%{conn: _, done: true} = continuation_state) do
    {[], continuation_state}
  end

  defp handle_sax_event(:startDocument, _location, stack) do
    [Parsers.LIST.new() | stack]
  end

  defp handle_sax_event(:endDocument, _location, stack) do
    [%Parsers.LIST{buffer: [result]}] = stack
    result
  end

  defp handle_sax_event({:startElement, _, element_name, _, attributes}, _location, stack) do
    parser_type = @parsers[element_name]
    if !parser_type, do: raise ParseError, "Unsupported element <#{element_name}>"
    attributes = attributes
                 |> Stream.map(fn {_, _, name, value} -> {name, value} end)
                 |> Enum.into(%{})
    [parser_type.new(attributes) | stack]
  end

  defp handle_sax_event({:endElement, _, element_name, _}, _location, stack) do
    [peek | stack] = stack
    parser_type = peek.__struct__
    if parser_type != @parsers[element_name] do
      start_element_name = parser_type |> to_string() |> String.split(".") |> List.last() |> String.downcase()
      raise ParseError, "End element </#{element_name}> does not match start element <#{start_element_name}>"
    end
    case parser_type.parse(peek) do
      {:ok, value, attributes} ->
        [peek | stack] = stack
        parser = peek.__struct__.update(peek, {value, attributes})
        [parser | stack]
      {:error, :invalid_format, str} ->
        raise ParseError, "Invalid format: #{str}"
    end
  end

  defp handle_sax_event({:characters, text}, _location, stack) do
    [peek | stack] = stack
    parser = peek.__struct__.update(peek, text)
    [parser | stack]
  end

  defp handle_sax_event(_, _location, stack) do
    stack
  end
end
