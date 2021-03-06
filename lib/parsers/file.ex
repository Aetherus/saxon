defmodule Saxon.Parsers.FILE do
  use Bitwise

  defstruct fd: nil, path: nil, buffer: "", attributes: %{}

  def new(attributes \\ %{}) do
    case Plug.Upload.random_file("saxon") do
      {:ok, path} ->
        {:ok, fd} = File.open(path, [:write, :binary, :delayed_write, :raw])
        %__MODULE__{fd: fd, attributes: attributes, path: path}
      {:too_many_attempts, _, _} -> {:error, :too_many_attempts}
      other -> other
    end
  end

  def update(%__MODULE__{fd: fd, buffer: buffer} = parser, chunk) do
    chunk = buffer <> (chunk |> String.replace(~r/\s/, ""))
    chunk_size = byte_size(chunk)
    t = chunk_size &&& 3
    h = chunk_size - t

    <<parsible :: binary-size(h),
      rest     :: binary-size(t)>> = chunk

    try do
      IO.binwrite(fd, Base.decode64!(parsible))
      %{parser | buffer: rest}
    rescue
      _ -> {:error, :invalid_format}
    end
  end

  def parse(%__MODULE__{fd: fd, buffer: "", attributes: attributes, path: path}) do
    File.close(fd)
    uploaded_file = %Plug.Upload{
      path: path,
      filename: attributes["filename"],
      content_type: attributes["content-type"]
    }
    {:ok, uploaded_file, attributes}
  end

  def parse(%__MODULE__{fd: fd}) do
   File.close(fd)
   {:error, :invalid_format, nil}
  end
end