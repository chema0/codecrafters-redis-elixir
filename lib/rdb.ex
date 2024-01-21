defmodule RDB do
  require Logger

  @spec parse_dbfile(binary()) :: {:ok, map()} | {:error, binary()}
  def parse_dbfile(filename) do
    case File.read(filename) do
      {:ok, data} -> parse(data)
      {:error, _} -> {:ok, %{}}
    end
  end

  defp parse(<<0x52, 0x45, 0x44, 0x49, 0x53, rest::binary>>) do
    parse(rest)
  end

  defp parse(<<0xFE, 0x00, 0xFB, 0x00, _, rest::binary>>) do
    parse_pairs(rest)
  end

  defp parse(<<0xFE, 0x00, 0xFB, 0x01, _, _, rest::binary>>) do
    parse_pairs(rest)
  end

  defp parse(<<0xFE, 0x00, 0xFB, 0x02, _, _, _, _, rest::binary>>) do
    parse_pairs(rest)
  end

  defp parse(<<_, rest::binary>>) do
    parse(rest)
  end

  defp parse_pairs(_, acc \\ [])

  defp parse_pairs(<<0xFF, _checksum::binary>>, acc) do
    acc
    |> Enum.chunk_every(2)
    |> Enum.map(fn [k, v] -> {k, v} end)
    |> Enum.into(%{})
    |> then(&{:ok, &1})
  end

  defp parse_pairs(<<n, rest::binary>>, acc) do
    acc = acc ++ [Kernel.binary_part(rest, 0, n)]
    parse_pairs(Kernel.binary_part(rest, n, byte_size(rest) - n), acc)
  end

  defp parse_pairs(_, _) do
    {:error, "invalid RDB file"}
  end

  # def parse_pairs(<<0, <<0::1, 0::1, _>>, _rest::binary>>) do
  # case length_prefix do
  #   <<0::1, 0::1, _>> ->
  #     IO.puts("The next 6 bits represent the length")

  #   <<0::1, 1::1, _>> ->
  #     IO.puts("Read one additional byte. The combined 14 bits represent the length")

  #   <<1::1, 0::1, _>> ->
  #     IO.puts(
  #       "Discard the remaining 6 bits. The next 4 bytes from the stream represent the length"
  #     )

  #   <<1::1, 1::1, _>> ->
  #     IO.puts(
  #       "The next object is encoded in a special format. The remaining 6 bits indicate the format."
  #     )
  # end
  # end
end
