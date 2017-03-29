defmodule Saxon.Parsers.LIST do
  defstruct buffer: [], attributes: %{}

  def new(attributes \\ %{}), do: %__MODULE__{attributes: attributes}

  def update(%__MODULE__{buffer: buffer} = parser, {chunk, _}) do
    %{parser | buffer: [chunk | buffer]}
  end

  def parse(%__MODULE__{buffer: buffer, attributes: attributes}) do
    {:ok, Enum.reverse(buffer), attributes}
  end
end