defmodule Storage do
  use Agent

  # TODO: refactor for better CLI support
  def start_link(config \\ %{}) do
    with dir when not is_nil(dir) <- Map.get(config, "dir"),
         dbfilename when not is_nil(dbfilename) <- Map.get(config, "dbfilename"),
         path <- Path.join([dir, dbfilename]),
         {:ok, data} <- RDB.parse_dbfile(path) do
      Agent.start_link(
        fn ->
          data
          |> Enum.reduce(%{config: config}, fn {key, value, timestamp}, acc ->
            cond do
              is_nil(timestamp) ->
                Map.put(acc, key, value)

              timestamp - :os.system_time(:millisecond) > 0 ->
                ttl = timestamp - :os.system_time(:millisecond)
                :timer.apply_after(ttl, __MODULE__, :delete, [key])
                Map.put(acc, key, value)

              true ->
                acc
            end
          end)
        end,
        name: __MODULE__
      )
    else
      _ ->
        case config do
          %{"replica_of" => replica_of} ->
            Agent.start_link(fn -> %{config: %{replica_of: replica_of}} end,
              name: __MODULE__
            )

          _ ->
            Agent.start_link(fn -> %{} end, name: __MODULE__)
        end
    end
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def get_keys() do
    Agent.get(__MODULE__, fn data ->
      data
      |> Map.drop([:config])
      |> Map.keys()
    end)
  end

  def set(key, value, opts \\ []) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))

    with {:ok, ttl} <- Keyword.fetch(opts, :ttl) do
      :timer.apply_after(ttl, __MODULE__, :delete, [key])
    end
  end

  def delete(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
  end
end
