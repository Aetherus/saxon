defmodule Saxon.Sax do
  @moduledoc "Simplified SAX parser"

  def start(conn, reducer, state, opts \\ %{}) do
    state = apply(reducer, :start_document, [state])
    continue(conn, reducer, "", state, opts)
  end

  defp continue(conn, reducer, tail, state, opts) do
    case Plug.Conn.read_body(conn, length: opts[:chunk_size]) do
      {status, chunk, conn} when status in [:ok, :more] ->
        parse(tail <> chunk, reducer, conn, state, status == :more, opts)
      other -> other
    end
  end

  defp parse("</" <> rest = chunk, reducer, conn, state, has_more, opts) do
    case String.split(rest, ~r/>/, parts: 2) do
      [tag, rest] ->
        state = apply(reducer, :end_element, [tag, state])
        parse(rest, reducer, conn, state, has_more, opts)
      [_broken_tag] ->
        continue(conn, reducer, chunk, state, opts)
    end
  end

  defp parse("<" <> rest = chunk, reducer, conn, state, has_more, opts) do
    case String.split(rest, ~r/\s*>/, parts: 2) do
      [tag, rest] ->
        {tag, attributes} = retrieve_attributes(tag)
        state = apply(reducer, :start_element, [tag, attributes, state])
        parse(rest, reducer, conn, state, has_more, opts)
      [_broken_tag] ->
        continue(conn, reducer, chunk, state, opts)
    end
  end

  defp parse("" = chunk, reducer, conn, state, true = _has_more, opts) do
    continue(conn, reducer, chunk, state, opts)
  end

  defp parse("", reducer, conn, state, false = _has_more, _opts) do
    apply(reducer, :end_document, [state, conn])
  end

  defp parse("&" <> _ = chunk, reducer, conn, state, has_more, opts) do
    case String.split(chunk, ~r/(?<=;)/, parts: 2) do
      [html_entity, rest] ->
        state = apply(reducer, :characters, [HtmlEntities.decode(html_entity), state])
        parse(rest, reducer, conn, state, has_more, opts)
      [_broken_entity] ->
        continue(conn, reducer, chunk, state, opts)
    end
  end

  defp parse(chunk, reducer, conn, state, has_more, opts) do
    case String.split(chunk, ~r/(?=[<&])/, parts: 2) do
      [text, rest] ->
        state = apply(reducer, :characters, [text, state])
        parse(rest, reducer, conn, state, has_more, opts)
      [text] ->
        state = apply(reducer, :characters, [text, state])
        continue(conn, reducer, "", state, opts)
    end
  end

  defp retrieve_attributes(chunk) do
    [tag | rest] = String.split(chunk, ~r/\s+/, parts: 2)
    attributes = Regex.scan(~r/([\w-]+)="([^"]+)"/, to_string(rest))
                 |> Stream.map(fn[_, name, value] -> {name, HtmlEntities.decode(value)} end)
                 |> Enum.into(%{})
    {tag, attributes}
  end
end