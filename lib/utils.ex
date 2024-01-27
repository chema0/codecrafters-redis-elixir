defmodule Utils do
  @type config :: [] | [{:dir, binary()}, {:dbfilename, binary()}]

  @spec parse_args() :: config()
  def parse_args() do
    case System.argv() |> IO.inspect() do
      ["--dir", dir, "--dbfilename", dbfilename] -> [dir: dir, dbfilename: dbfilename]
      _ -> []
    end
  end
end
