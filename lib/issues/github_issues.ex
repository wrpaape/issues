defmodule Issues.GithubIssues do
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
    _issues_url(user, project)
    |> HTTPoison.get(_user_agent)
    |> _extract_response
    |> _handle_response
  end

  def _issues_url(user, project) do
    "https://api.github.com/repos/#{user}/#{project}/issues"
  end

  defp _extract_response({_status, response}), do: response

  defp _handle_response(%{status_code: 200, body: body}) do
    { :ok, :jsx.decode(body) }
  end

  defp _handle_response(%{status_code: ___, body: body}) do
    { :error, :jsx.decode(body) }
  end
end