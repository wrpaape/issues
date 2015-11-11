defmodule Issues.GithubIssues do
  @github_url Application.get_env(:issues, :github_url)
  @parse_opts [labels: :atom, return_maps: :true]

  defp _user_agent, do: [{"User-Agent", _user_agent_string}]
  defp _user_agent_string do
    """ 
    Mozilla/5.0
    (Macintosh; Intel Mac OS X 10_10_5)
    AppleWebKit/537.36
    (KHTML, like Gecko)
    Chrome/46.0.2490.80
    Safari/537.36
    wrpaape@gmail.com
    """
    |> String.rstrip
    |> String.replace(~r/\n/, " ")
  end

  def fetch(user, project) do
    issues_url(user, project)
    |> HTTPoison.get(_user_agent)
    |> extract_response
    |> handle_response
  end

  def issues_url(user, project) do
    "#{@github_url}/repos/#{user}/#{project}/issues"
  end

  def extract_response({_status, response}), do: response

  def handle_response(%{status_code: 200, body: body}) do
    { :ok, :jsx.decode(body, @parse_opts) }
  end

  def handle_response(%{status_code: ___, body: body}) do
    { :error, :jsx.decode(body, @parse_opts) }
  end
end