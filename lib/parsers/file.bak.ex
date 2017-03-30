#defmodule Saxon.Parsers.FILE do
#  use GenServer
#  defstruct [:pid]
#
#  def new(attributes \\ %{}) do
#    {:ok, pid} = GenServer.start_link(__MODULE__, attributes)
#    %__MODULE__{pid: pid}
#  end
#
#  def update(%__MODULE__{pid: pid} = parser, chunk) do
#    GenServer.cast(pid, {:update, chunk})
#    parser
#  end
#
#  def parse(%__MODULE__{pid: pid}) do
#    GenServer.call(pid, :parse)
#  end
#
#  def init(attributes) do
#    tmp_path = Plug.Upload.random_file!("saxon")
#    fd = File.open!(tmp_path, [:write, :binary])
#    {:ok, %{fd: fd, path: tmp_path, attributes: attributes}}
#  end
#
#  def handle_cast({:update, chunk}, %{fd: fd} = state) do
#    binary = chunk |> to_string() |> Base.decode64!(ignore: :whitespace)
#    IO.binwrite(fd, binary)
#    {:noreply, state}
#  end
#
#  def handle_call(:parse, _from, %{fd: fd, path: path, attributes: attributes} = state) do
#    File.close(fd)
#    uploaded_file = %Plug.Upload{
#      path: path,
#      filename: to_string(attributes['filename']),
#      content_type: to_string(attributes['content-type'])
#    }
#    {:stop, :normal, {:ok, uploaded_file, attributes}, state}
#  end
#end