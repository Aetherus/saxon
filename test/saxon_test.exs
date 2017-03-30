defmodule SaxonTest do
  use ExUnit.Case
  doctest Saxon

  test "parse" do
    conn = Plug.Test.conn(:post, "/", File.read!("test/fixture.xml"))
    {:ok, params, _} = Saxon.parse(conn, "application", "vnd.saxon+xml", nil, nil)

    %{
      "article" => %{
        "title" => "Elixir Rocks",
        "author_id" => 1,
        "published_at" => %DateTime{},
        "private" => false,
        "logo" => %Plug.Upload{filename: "logo.png", content_type: "image/png", path: path1},
        "sections" => [
          %{
            "content" => "Elixir really rocks.",
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
end
