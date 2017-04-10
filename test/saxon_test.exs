defmodule SaxonTest do
  use ExUnit.Case
  doctest Saxon

  test "parse" do

    conn = benchmark("Initialize", fn ->
      Plug.Test.conn(:post, "/", File.read!("test/fixture.xml"))
    end)

    {:ok, params, _conn} = benchmark("Parse", fn ->
      Saxon.parse(conn, "application", "vnd.saxon+xml", nil, [saxon_chunk_size: 16384])
    end)

    %{
      "article" => %{
        "title" => "Elixir 真牛！",
        "author_id" => 1,
        "published_at" => %DateTime{},
        "private" => false,
        "logo" => %Plug.Upload{filename: "logo.png", content_type: "image/png", path: path1},
        "sections" => [
          %{
            "content" => "Elixir 真的很牛。",
            "photo" => %Plug.Upload{filename: "awesome.jpg", content_type: "image/jpeg", path: path2}
          },
          %{
            "content" => "Lorem ipsum ...",
            "photo" => %Plug.Upload{filename: "cool.jpg", content_type: "image/jpeg", path: path3}
          }
        ]
      }
    } = params

    assert File.exists? path1
    assert File.exists? path2
    assert File.exists? path3
  end

  defp benchmark(title, func) do
    %{second: sec, microsecond: {msec, _}} = DateTime.utc_now()
    bfr = sec * 1_000_000 + msec
    result = func.()
    %{second: sec, microsecond: {msec, _}} = DateTime.utc_now()
    aftr = sec * 1_000_000 + msec
    IO.puts "#{title}: #{aftr - bfr} microseconds"
    result
  end
end
