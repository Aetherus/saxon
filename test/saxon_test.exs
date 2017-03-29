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
        "logo" => %Plug.Upload{filename: "logo.png", content_type: "image/png"},
        "sections" => [
          %{
            "content" => "Elixir really rocks.",
            "photo" => %Plug.Upload{filename: "awesome.jpg", content_type: "image/jpeg"}
          },
          %{
            "content" => "Lorem ipsum ...",
            "photo" => %Plug.Upload{filename: "cool.jpg", content_type: "image/jpeg"}
          }
        ]
      }
    } = params
  end
end
