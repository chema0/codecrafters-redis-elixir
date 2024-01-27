defmodule RDB do
  @moduledoc """
  This module implements tools to work with RDB (Redis Database) persistence. Partial support
  of the RDB file format.

  https://rdb.fnordig.de/file_format.html
  """

  require Logger

  @spec parse_dbfile(binary()) :: {:ok, list()} | {:error, binary()}
  def parse_dbfile(filename) do
    case read_file(filename) do
      <<>> ->
        {:ok, []}

      data ->
        parse(data)
    end
  end

  defp parse(<<0xFE, 0x00, 0xFB, _hash_table_size, _hash_table_expire_size, rest::binary>>) do
    IO.puts("# Key-Value pair starts")
    parse_pairs(rest)
  end

  defp parse(<<_, rest::binary>>) do
    parse(rest)
  end

  defp parse(<<>>), do: {:ok, []}

  defp parse_pairs(_, acc \\ [])

  defp parse_pairs(<<0xFF, _checksum::binary>>, acc) do
    {:ok, acc}
  end

  # TODO: refactor to avoid duplicated pattern matching when handling expires
  defp parse_pairs(
         <<0xFD, ttl_seconds::32-little, _type, key_size, key::binary-size(key_size), value_size,
           value::binary-size(value_size), rest::binary>>,
         acc
       ) do
    acc = acc ++ [{key, value, :timer.seconds(ttl_seconds)}]
    parse_pairs(rest, acc)
  end

  # TODO: refactor to avoid duplicated pattern matching when handling expires
  defp parse_pairs(
         <<0xFC, ttl_ms::64-little, _type, key_size, key::binary-size(key_size), value_size,
           value::binary-size(value_size), rest::binary>>,
         acc
       ) do
    acc = acc ++ [{key, value, ttl_ms}]
    parse_pairs(rest, acc)
  end

  # defp parse_pairs(<<_type, n, rest::binary>>, acc) do
  defp parse_pairs(
         <<_type, key_size, key::binary-size(key_size), value_size,
           value::binary-size(value_size), rest::binary>>,
         acc
       ) do
    acc = acc ++ [{key, value, nil}]
    parse_pairs(rest, acc)
  end

  defp parse_pairs(_, _) do
    {:error, "invalid RDB file"}
  end

  def read_file(filename) do
    case File.read(filename) do
      {:ok, data} ->
        data

      {:error, _} ->
        <<>>
    end
  end
end
