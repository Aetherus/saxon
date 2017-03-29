defmodule SaxonTest do
  use ExUnit.Case
  doctest Saxon

  test "parse" do
    conn = Plug.Test.conn(:post, "/", File.read!("test/fixture.xml"))
    {:ok, _} = Saxon.parse(conn, "application", "vnd.saxon+xml", nil, nil)
  end
end
