defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """
  require Logger

  use Application

  @default_port 6379

  def start(_type, _args) do
    args = Utils.parse_args()

    Supervisor.start_link(
      [
        {Task.Supervisor, name: __MODULE__.TaskSupervisor},
        {Task, fn -> Server.listen(args) end},
        {Storage, Enum.into(args, %{}, fn {k, v} -> {to_string(k), v} end)}
      ],
      strategy: :one_for_one
    )
  end

  @doc """
  Listen for incoming connections
  """
  # TODO: extend to support `opts` extra arg (use to include is_mater option and execute handshake depending on the value)
  @spec listen(
          port: non_neg_integer(),
          replica_of: Utils.replica_of() | nil
        ) :: no_return()
  def listen(opts) do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    port = Keyword.get(opts, :port, @default_port)
    replica_of = Keyword.get(opts, :replica_of)

    do_replication_handshake(replica_of)

    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  @spec loop_acceptor(:gen_tcp.socket()) :: no_return()
  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(
        __MODULE__.TaskSupervisor,
        fn -> serve(client) end
      )

    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  @spec serve(:gen_tcp.socket()) :: any
  defp serve(socket) do
    with {:ok, packet} <- do_recv(socket),
         {:ok, data, _} <- Parser.parse(packet),
         {:ok, response} <- Commands.exec(data) do
      write(socket, response)
      serve(socket)
    end
  end

  defp do_recv(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write(socket, packet) do
    :gen_tcp.send(socket, packet)
  end

  @spec do_replication_handshake(Utils.replica_of()) :: :ok
  defp do_replication_handshake(nil), do: :ok

  # TODO: better error handling on handshake error
  defp do_replication_handshake({master_host, master_port}) do
    with {:ok, addr} <- :inet.getaddr(to_charlist(master_host), :inet),
         {:ok, conn} <-
           :gen_tcp.connect(%{family: :inet, port: master_port, addr: addr}, [
             :binary,
             active: false,
             reuseaddr: true
           ]) do
      :ok = :gen_tcp.send(conn, Builder.build_list(["ping"]))
    else
      {:error, reason} ->
        Logger.error("Error during replication handshake: #{inspect(reason)}")
    end
  end
end
