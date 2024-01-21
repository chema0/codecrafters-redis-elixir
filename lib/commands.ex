defmodule Commands do
  @spec exec(list()) :: {:ok, response :: binary()}
  def exec(command)

  def exec(["ping" | _]) do
    {:ok, Builder.build_simple_string("PONG")}
  end

  def exec(["echo" | [message]]) do
    {:ok, Builder.build_bulk_string(message)}
  end

  def exec(["set", key, value]) do
    Storage.set(key, value)
    {:ok, Builder.build_simple_string("OK")}
  end

  def exec(["set", key, value, "px", px]) do
    px = String.to_integer(px)

    Storage.set(key, value, ttl: px)

    {:ok, Builder.build_simple_string("OK")}
  end

  def exec(["get", key]) do
    case Storage.get(key) do
      nil ->
        {:ok, Builder.build_null_bulk_string()}

      value ->
        {:ok, Builder.build_bulk_string(value)}
    end
  end

  def exec(["config", "get", key]) do
    config = Storage.get(:config)

    case Map.get(config, key) do
      nil ->
        {:ok, Builder.build_list([])}

      value ->
        {:ok, Builder.build_list([key, value])}
    end
  end

  def exec(["keys", "*"]) do
    case Storage.get_keys() do
      [] -> {:ok, Builder.build_list([])}
      keys -> {:ok, Builder.build_list(keys)}
    end
  end

  def exec([cmd | _]), do: {:ok, Builder.build_error("unkown command '#{cmd}'")}
end
