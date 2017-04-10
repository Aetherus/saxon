defmodule Saxon.Sax do
  @moduledoc """
  An overly simplified SAX parser, aiming at reducing memory footprint when dealing with large text nodes.

  Supports **only** the following events:

  *  `:start_document (state)`
  *  `:end_document (state, conn)`
  *  `:start_element (element_name, attributes, state)`
  *  `:end_element (element_name, state)`
  *  `:characters (chunk, state)`

  Note that the `:ignorableWhitespace` event in xmerl or erlsom will be treated as `:characters`.

  Even if there is only one piece of text in the element, the event `:characters` can be triggered multiple times,
  each time feeding a HTML entity decoded chunk to the event handler.
  The sizes of the chunks can diverse hugely, so the handler should not make decision based on the chunk size.
  """

  def start(conn, reducer, opts \\ %{}) do
    state = apply(reducer, :init, [])
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

  defp parse(<<"</", rest::binary>> = chunk, reducer, conn, state, has_more, opts) do
    case split_before(rest, '>') do
      {tag, <<">", rest::binary>>} ->
        state = apply(reducer, :end_element, [tag, state])
        parse(rest, reducer, conn, state, has_more, opts)
      _broken_tag ->
        continue(conn, reducer, chunk, state, opts)
    end
  end

  defp parse(<<"<", rest::binary>> = chunk, reducer, conn, state, has_more, opts) do
    case split_before(rest, '>') do
      {tag, <<">", rest::binary>>} ->
        {tag, attributes} = retrieve_attributes(tag)
        state = apply(reducer, :start_element, [tag, attributes, state])
        parse(rest, reducer, conn, state, has_more, opts)
      _broken_tag ->
        continue(conn, reducer, chunk, state, opts)
    end
  end

  defp parse("" = chunk, reducer, conn, state, true = _has_more, opts) do
    continue(conn, reducer, chunk, state, opts)
  end

  defp parse("", reducer, conn, state, false = _has_more, _opts) do
    apply(reducer, :end_document, [state, conn])
  end

  defp parse(<<"&", _::binary>> = chunk, reducer, conn, state, has_more, opts) do
    case split_after(chunk, ';') do
      {html_entity, rest} ->
        state = apply(reducer, :characters, [HtmlEntities.decode(html_entity), state])
        parse(rest, reducer, conn, state, has_more, opts)
      _broken_entity ->
        continue(conn, reducer, chunk, state, opts)
    end
  end

  defp parse(chunk, reducer, conn, state, has_more, opts) do
    case split_before(chunk, '<&') do
      {text, rest} ->
        state = apply(reducer, :characters, [text, state])
        parse(rest, reducer, conn, state, has_more, opts)
      text ->
        state = apply(reducer, :characters, [text, state])
        continue(conn, reducer, "", state, opts)
    end
  end

  defp retrieve_attributes(chunk) do
    case split_before(chunk, ' ') do
      {tag, ""} ->
        {tag, %{}}
      {tag, rest} ->
        attributes = Regex.scan(~r/([\w-]+)="([^"]+)"/, IO.iodata_to_binary(rest))
                     |> Stream.map(fn[_, name, value] -> {name, HtmlEntities.decode(value)} end)
                     |> Enum.into(%{})
        {tag, attributes}
      tag ->
        {tag, %{}}
    end
  end

  defp split_after(str, chars) do
    split_after(chars, str, [], str)
  end

  defp split_after(chars, <<c, rest::binary>>, acc, original) do
    if c in chars do
      {IO.iodata_to_binary([acc, c]), rest}
    else
      split_after(chars, rest, [acc, c], original)
    end
  end

  defp split_after(_chars, "", _acc, original), do: original

  defp split_before(str, chars) do
    split_before(chars, str, [], str)
  end

  defp split_before(chars, <<c, rest::binary>> = tail, acc, original) do
    if c in chars do
      {IO.iodata_to_binary(acc), tail}
    else
      split_before(chars, rest, [acc, c], original)
    end
  end

  defp split_before(_chars, "", _acc, original), do: original
end