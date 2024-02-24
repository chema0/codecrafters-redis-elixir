defmodule Replication do
  @master_replid "8371b4fb1155b71f4a04d3e1bc3e18c4a990aeeb"
  @master_repl_offset 0

  def get_replication_info() do
    config = Storage.get(:config) || %{}

    case Map.get(config, :replica_of) do
      nil ->
        Builder.build_bulk_string(
          "# Replication\nrole:master\nmaster_replid:#{@master_replid}\nmaster_repl_offset:#{@master_repl_offset}"
        )

      _ ->
        Builder.build_bulk_string("# Replication \nrole:slave")
    end
  end
end
