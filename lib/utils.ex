defmodule Utils do
  @type config :: [] | [{:dir, binary()}, {:dbfilename, binary()}]

  @spec parse_args!() :: config() | no_return()
  def parse_args!() do
    case System.argv() do
      [] -> []
      ["--dir", dir, "--dbfilename", dbfilename] -> [dir: dir, dbfilename: dbfilename]
      _ -> raise ArgumentError
    end
  end
end
