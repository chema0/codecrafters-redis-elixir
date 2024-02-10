defmodule Utils do
  @type config :: [] | [{:dir, binary()}, {:dbfilename, binary()}]

  @spec parse_args() :: config()
  def parse_args() do
    case System.argv() do
      ["--dir", dir, "--dbfilename", dbfilename] -> [dir: dir, dbfilename: dbfilename]
      ["--port", port] -> [port: String.to_integer(port)]
      _ -> []
    end
  end
end
