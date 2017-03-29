defmodule Saxon.Parsers.TIMESTAMP do
  defstruct buffer: [], attributes: %{}

  def new(attributes \\ %{}), do: %__MODULE__{attributes: attributes}

  def update(%__MODULE__{buffer: buffer} = parser, chunk) do
    %{parser | buffer: [buffer, chunk]}
  end

  def parse(%__MODULE__{buffer: buffer, attributes: attributes}) do
    buffer = buffer |> to_string() |> String.trim()
    parse(buffer, attributes)
  end

  defp parse("", attributes) do
    {:ok, nil, attributes}
  end

  defp parse(buffer, attributes) do
    case (buffer |> DateTime.from_iso8601()) do
      {:ok, timestamp, _} ->
        {:ok, timestamp, attributes}
      _ ->
        {:error, :invalid_format, buffer}
    end
  end
end