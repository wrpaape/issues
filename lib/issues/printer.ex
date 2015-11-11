defmodule Issues.Printer do
  @header_keys Application.get_env(:issues, :header_keys)

  @moduledoc """
  Prints github issues that have been decoded from json, sorted, and selected
  in a neat table format.
  """

  def process(issues) do
    issues
    |> calc_cols_params
    |> Enum.map(&format_col/1)
    |> List.zip
    |> Enum.with_index
    |> Enum.each(&print_row/1)
  end

  def calc_cols_params(issues) do
    @header_keys
    |> Enum.map(&col_params(&1, issues))
  end

  def col_params(key, issues) do
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

  def string_params(string) do
    [length: String.length(string), string: string]
  end

  def format_col([{:vals_params, vals_params} | key_params]) do
    width_param = 
      key_params
      |> List.first
    
    col_head = 
      key_params
      |> center
      |> add_border

    vals_params
    |> Enum.map(&center([width_param | &1]))
    |> Enum.into(col_head)
  end

  def center([max_width: max_width, length: length, string: string]) do 
    [lpad, rpad] = calc_pads(max_width, length)

    lpad <> string <> rpad
  end

  def calc_pads(max_width, length) do
    max_width
    |> - length
    |> div_rem_2
    |> pad_lengths
    |> Enum.map(&String.duplicate(" ", &1))
  end
  
  def pad_lengths([lpad, offset]), do: [lpad, lpad + offset]
  
  def div_rem_2(int), do: [div(int, 2), rem(int, 2)]

  def add_border(col_head) do
    border_length = 
      col_head
      |> String.length
    
    [col_head, String.duplicate("─", border_length)]
  end

  def print_row({border, 1}),   do: print_row(border, "┼")
  def print_row({row, _index}), do: print_row(row, "│")
  def print_row(row, joiner) do
    row
    |> Tuple.to_list
    |> Enum.join(joiner)
    |> IO.puts
  end
end