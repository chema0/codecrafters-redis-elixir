defmodule Replication do
  def get_replication_info() do
    config = Storage.get(:config) || %{}

    case Map.get(config, :replica_of) do
      nil ->
        Builder.build_bulk_string("# Replication\nrole:master")

      _ ->
        Builder.build_bulk_string("# Replication \nrole:slave")
    end
  end
end
