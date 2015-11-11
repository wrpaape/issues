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
    |> format_and_print
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

  def string_params(string) do
    [length: String.length(string), string: string]
  end

  def print_params(key, issues) do
    key_params =
      key
      |> Atom.to_string
      |> string_params
    vals_params =
      issues
      |> Enum.map(&string_params("#{&1[key]}"))
    max_width = 
      vals_params
      |> Enum.max
      |> Keyword.fetch!(:length)
      |> max(key_params[:length])
      |> + 2

    [vals_params: vals_params, max_width: max_width] ++ key_params
  end

  def calc_format_params(issues) do
    @header_keys
    |> Enum.map(&print_params(&1, issues))
  end

  def div_rem_2(int), do: [div(int, 2), rem(int, 2)]
  def pad_lengths([lpad, offset]), do: [lpad, lpad + offset]
  def calc_pads(max_width, length) do
    max_width
    |> - length
    |> div_rem_2
    |> pad_lengths
    |> Enum.map(&String.duplicate(" ", &1))
  end

  def center([max_width: max_width, length: length, string: string]) do 
    [lpad, rpad] = calc_pads(max_width, length)

    lpad <> string <> rpad
  end

  def format([{:vals_params, vals_params} | key_params]) do
    width_param = 
      key_params
      |> List.first
    col_head = 
      key_params
      |> center

    vals_params
      |> Enum.map(&center([width_param | &1]))
      |> List.insert_at(0, col_head)
  end

  def print_row(cols) do
    cols
    |> Tuple.to_list
    |> Enum.join("|")
    |> IO.puts
  end

  def format_and_print(issues) do
    issues
    |> calc_format_params
    |> Enum.map(&format/1)
    |> List.zip
    |> Enum.each(&print_row/1)
  end
end