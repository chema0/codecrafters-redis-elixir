defmodule Builder do
  @crlf "\r\n"

  @spec build_bulk_string(binary()) :: binary()
  def build_bulk_string(<<>>) do
    "$0" <> @crlf <> @crlf
  end

  def build_bulk_string(value) do
    "$#{byte_size(value)}" <> @crlf <> value <> @crlf
  end
end
