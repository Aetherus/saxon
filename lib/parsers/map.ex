defmodule Saxon.Parsers.MAP do
  defstruct buffer: %{}, attributes: %{}

  def new(attributes \\ %{}), do: %__MODULE__{attributes: attributes}

  def update(%__MODULE__{buffer: buffer} = parser, {value, %{"name" => name}}) do
    %{parser | buffer: Map.put(buffer, name, value)}
  end

  def update(%__MODULE__{buffer: _} = parser, _) do
    parser
  end

  def parse(%__MODULE__{buffer: buffer, attributes: attributes}) do
    {:ok, buffer, attributes}
  end
end