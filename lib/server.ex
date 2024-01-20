defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application

  def start(_type, _args) do
    args = Utils.parse_args!()

    Supervisor.start_link(
      [
        {Task.Supervisor, name: __MODULE__.TaskSupervisor},
        {Task, fn -> Server.listen() end},
        {Storage, %{config: Enum.into(args, %{}, fn {k, v} -> {to_string(k), v} end)}}
      ],
      strategy: :one_for_one
    )
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])

    loop_acceptor(socket)
  end

  @spec serve(:gen_tcp.socket()) :: any
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
         {:ok, response} <- check_command(data) do
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

  defp check_command(["ping" | _]) do
    {:ok, Builder.build_simple_string("PONG")}
  end

  defp check_command(["echo" | [message]]) do
    {:ok, Builder.build_bulk_string(message)}
  end

  defp check_command(["set", key, value]) do
    Storage.set(key, value)
    {:ok, Builder.build_simple_string("OK")}
  end

  defp check_command(["set", key, value, "px", px]) do
    px = String.to_integer(px)

    Storage.set(key, value, ttl: px)

    {:ok, Builder.build_simple_string("OK")}
  end

  defp check_command(["get", key]) do
    case Storage.get(key) do
      nil ->
        {:ok, Builder.build_null_bulk_string()}

      value ->
        {:ok, Builder.build_bulk_string(value)}
    end
  end

  defp check_command(["config", "get", key]) do
    config = Storage.get(:config)

    case Map.get(config, key) do
      nil ->
        {:ok, Builder.build_list([])}

      value ->
        {:ok, Builder.build_list([key, value])}
    end
  end
end
