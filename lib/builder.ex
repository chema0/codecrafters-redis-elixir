defmodule Builder do
  @crlf "\r\n"

  @spec build_bulk_string(binary()) :: binary()
  def build_bulk_string(value)

  def build_bulk_string(<<>>) do
    "$0" <> @crlf <> @crlf
  end

  def build_bulk_string(value) do
    "$#{byte_size(value)}" <> @crlf <> value <> @crlf
  end

  @spec build_null_bulk_string() :: binary()
  def build_null_bulk_string(), do: "$-1" <> @crlf

  @spec build_simple_string(binary()) :: binary()
  def build_simple_string(value), do: "+" <> value <> @crlf

  @spec build_list([binary()]) :: binary()
  def build_list(values)

  def build_list([]), do: "*0" <> @crlf

  def build_list(values) do
    list =
      values
      |> Enum.map(&build_bulk_string/1)
      |> Enum.join("")

    "*#{length(values)}" <> @crlf <> list <> @crlf
  end
end
