defmodule Saxon.Reducer do
  import Plug.Conn
  alias Plug.Parsers.ParseError
  alias Saxon.Parsers

  @parsers %{
    "boolean" => Parsers.BOOLEAN,
    "file" => Parsers.FILE,
    "float" => Parsers.FLOAT,
    "integer" => Parsers.INTEGER,
    "list" => Parsers.LIST,
    "map" => Parsers.MAP,
    "string" => Parsers.STRING,
    "timestamp" => Parsers.TIMESTAMP
  }

  def init, do: []

  def start_document(stack) do
    [Parsers.LIST.new() | stack]
  end

  def end_document(stack, conn) do
    [%Parsers.LIST{buffer: [result]}] = stack
    {result, conn}
  end

  def start_element(tag, attributes, stack) do
    parser_type = @parsers[tag]
    if !parser_type, do: raise ParseError, "Unsupported tag <#{tag}>"
    [parser_type.new(attributes) | stack]
  end

  def end_element(end_tag, stack) do
    [peek | stack] = stack
    parser_type = peek.__struct__
    if parser_type != @parsers[end_tag] do
      raise ParseError, "Invalid end tag </#{end_tag}>"
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

  def characters(chunk, stack) do
    [peek | stack] = stack
    parser = peek.__struct__.update(peek, chunk)
    [parser | stack]
  end
end