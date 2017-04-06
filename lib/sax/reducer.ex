defmodule Saxon.Reducer do
  alias Plug.Parsers.ParseError

  def init, do: []

  def start_document(stack) do
    [Saxon.Parsers.LIST.new() | stack]
  end

  def end_document(stack, conn) do
    [%Saxon.Parsers.LIST{buffer: [result]}] = stack
    {result, conn}
  end

  def start_element(tag, attributes, stack) do
    parser_type = parser_for(tag)
    if !parser_type do
      raise ParseError, "Unsupported tag <#{tag}>"
    end
    [apply(parser_type, :new, [attributes]) | stack]
  end

  def end_element(end_tag, stack) do
    [peek | stack] = stack
    parser_type = peek.__struct__
    if parser_type != parser_for(end_tag) do
      raise ParseError, "Invalid end tag </#{end_tag}>"
    end
    case apply(parser_type, :parse, [peek]) do
      {:ok, value, attributes} ->
        [peek | stack] = stack
        parser = apply(peek.__struct__, :update, [peek, {value, attributes}])
        [parser | stack]
      {:error, :invalid_format, str} ->
        raise ParseError, "Invalid format: #{str}"
    end
  end

  def characters(chunk, stack) do
    [peek | stack] = stack
    parser = apply(peek.__struct__, :update, [peek, chunk])
    [parser | stack]
  end

  for tag <- ~w(boolean file float integer list map string timestamp) do
    defp parser_for(unquote(tag)), do: unquote("Elixir.Saxon.Parsers.#{String.upcase(tag)}" |> String.to_atom)
  end

  defp parser_for(_), do: nil
end