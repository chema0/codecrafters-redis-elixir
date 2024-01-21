defmodule Storage do
  use Agent

  def start_link(config \\ %{}) do
    with dir when not is_nil(dir) <- Map.get(config, "dir"),
         dbfilename when not is_nil(dbfilename) <- Map.get(config, "dbfilename"),
         path <- Path.join([dir, dbfilename]),
         {:ok, data} <- RDB.parse_dbfile(path) do
      Agent.start_link(
        fn ->
          %{}
          |> Map.merge(%{config: config})
          |> Map.merge(data)
          |> IO.inspect()
        end,
        name: __MODULE__
      )
    else
      _ -> Agent.start_link(fn -> %{} end, name: __MODULE__)
    end
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
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
