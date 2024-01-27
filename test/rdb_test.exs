defmodule RDBTest do
  use ExUnit.Case, async: true

  @filename "test/dump.rdb"

  test "read_file/1" do
    assert RDB.read_file(@filename) != <<>>
  end

  test "read_file/1 on non-existent file" do
    assert RDB.read_file("foo.rdb") == <<>>
  end

  test "parse_dbfile/1" do
    {:ok, data} = RDB.parse_dbfile(@filename)
    assert data == [{"hello", "world", 1_705_867_568_423}, {"mykey", "myval", nil}]
  end
end
