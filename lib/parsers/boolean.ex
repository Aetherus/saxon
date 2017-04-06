defmodule Saxon.Parsers.BOOLEAN do
  defstruct buffer: [], attributes: %{}

  def new(attributes \\ %{}), do: %__MODULE__{attributes: attributes}

  def update(%__MODULE__{buffer: buffer} = parser, chunk) do
    %{parser | buffer: [buffer, chunk]}
  end

  def parse(%__MODULE__{buffer: buffer, attributes: attributes}) do
    buffer = buffer |> IO.iodata_to_binary() |> String.trim()
    case buffer do
      "true" -> {:ok, true, attributes}
      "false" -> {:ok, false, attributes}
      "" -> {:ok, nil, attributes}
      _ -> {:error, :invalid_format, buffer}
    end
  end
end