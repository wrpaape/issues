defmodule Issues.CLI do
  @default_count 4
  @sort_by Application.get_env(:issues, :sort_by)
  @header_keys Application.get_env(:issues, :header_keys)

  @moduledoc """
  Handle the command line parsing and the dispatch to the various functions
  that end up generating a table of the last _n_ issues in a github project
  """
  
  def run(argv) do
    argv
    |> parse_args
    |> process
  end


  def process(:help) do
    """
    usage: issues <user> <project> [ count | #{@default_count} ]
    """
    |> IO.puts

    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response
    |> sort_into_ascending_order
    |> Enum.take(count)
    |> format_issues
  end

  def decode_response({:ok, body}),    do: body
  def decode_response({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)
    IO.puts "Error fetching from Github: #{message}"
    System.halt(2)
  end

  def sort_into_ascending_order(list_of_issues) do
    list_of_issues
    |> Enum.sort_by(&(&1[@sort_by]))
  end

  @doc """
  `argv` can be -h or --help, which returns :help.
  Otherwise it is a github user name, project name, and (optionally)
  the number of entries to format.
  Return a tuple of `{ user, project, count }`, or `:help` if help was given.
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [ help: :boolean],
                                     aliases:  [ h:    :help   ])
    case parse do
      { [ help: true ], _, _ }
        -> :help
      
      { _, [ user, project, count ], _ }
        -> { user, project, String.to_integer(count) }
      
      { _, [ user, project ], _ }
        -> { user, project, @default_count }
      
      _ -> :help
    end
  end

  def key_params(key, issues) do
    key_str =
      key
      |> Atom.to_string
    key_len = 
      key_str
      |> String.length
    val_len =
      issues
      |> Enum.map(&String.length("#{&1[key]}"))
      |> Enum.max
    max_width = 
      key_len
      |> max(val_len)
      |> + 2

    %{key: key, string: key_str, length: key_len, max_width: max_width}
  end

  def calc_print_params(issues) do
    @header_keys
    |> Enum.map(&key_params(&1, issues))
  end

  def map_funcs(funcs, args), do: funcs |> Enum.map(&apply(&1, args))
  def div_rem_2(int) do
    [&div/2, &rem/2]
    |> map_funcs([int, 2])
  end

  def pad_lengths([lpad, offset]), do: [lpad, lpad + offset]
  def calc_pads(max_width, string) do
    max_width - String.length(string)
    |> div_rem_2
    |> pad_lengths
    |> Enum.map(&String.duplicate(" ", &1))
  end

  def center(%{string: string, max_width: max_width}) do 
    [lpad, rpad] = calc_pads(max_width, string)

    lpad <> str <> rpad
  end

  def print(print_params) do
    # IO.inspect print_params
    print_params
    |> Enum.map_join("|", &center/1)
  end

  def format_issues(issues) do
    print_params =
    issues
    |> calc_print_params
    |> print
  end
end