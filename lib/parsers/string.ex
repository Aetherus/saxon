defmodule Saxon.Parsers.STRING do
  defstruct buffer: [], attributes: %{}
  def new(attributes \\ %{}), do: %__MODULE__{attributes: attributes}

  def update(%__MODULE__{buffer: buffer} = parser, chunk) do
    %{parser | buffer: [buffer, chunk]}
  end

  def parse(%__MODULE__{buffer: buffer, attributes: attributes}) do
    result = buffer |> to_string()
    {:ok, result, attributes}
  end
end