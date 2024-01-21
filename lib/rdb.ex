defmodule RDB do
  @moduledoc """
  This module implements tools to work with RDB (Redis Database) persistence. Partial support
  of the RDB file format.

  https://rdb.fnordig.de/file_format.html
  """

  require Logger

  @spec parse_dbfile(binary()) :: {:ok, map()} | {:error, binary()}
  def parse_dbfile(filename) do
    case File.read(filename) do
      {:ok, data} ->
        parse(data)

      {:error, _} ->
        {:ok, %{}}
    end
  end

  defp parse(<<0x52, 0x45, 0x44, 0x49, 0x53, rest::binary>>) do
    parse(rest)
  end

  defp parse(<<0xFE, 0x00, 0xFB, _hash_table_size, _, _, rest::binary>>) do
    parse_pairs(rest)
  end

  defp parse(<<_, rest::binary>>) do
    parse(rest)
  end

  defp parse(<<>>), do: {:ok, %{}}

  defp parse_pairs(_, acc \\ [])

  defp parse_pairs(<<0xFF, _checksum::binary>>, acc) do
    acc
    |> Enum.chunk_every(2)
    |> Enum.map(fn [k, v] -> {k, v} end)
    |> Enum.into(%{})
    |> then(&{:ok, &1})
  end

  defp parse_pairs(<<0, rest::binary>>, acc) do
    parse_pairs(rest, acc)
  end

  defp parse_pairs(<<n, rest::binary>>, acc) do
    acc = acc ++ [Kernel.binary_part(rest, 0, n)]
    parse_pairs(Kernel.binary_part(rest, n, byte_size(rest) - n), acc)
  end

  defp parse_pairs(_, _) do
    {:error, "invalid RDB file"}
  end
end
