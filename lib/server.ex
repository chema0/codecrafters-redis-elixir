defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application

  @default_port 6379

  def start(_type, _args) do
    args = Utils.parse_args()

    Supervisor.start_link(
      [
        {Task.Supervisor, name: __MODULE__.TaskSupervisor},
        {Task, fn -> Server.listen(Keyword.get(args, :port, @default_port)) end},
        {Storage, Enum.into(args, %{}, fn {k, v} -> {to_string(k), v} end)}
      ],
      strategy: :one_for_one
    )
  end

  @doc """
  Listen for incoming connections
  """
  @spec listen(pos_integer()) :: no_return()
  def listen(port) do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

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
end
