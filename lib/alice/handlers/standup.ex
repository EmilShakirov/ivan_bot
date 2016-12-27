defmodule Alice.Handlers.Standup do
  @moduledoc """
  Alice.Handlers.Standup is a slack handler for managing incoming slack bot messages
  """

  @valid_project_name_warning """
  Please enter valid command: `standup %PROJECT_NAME%`
  Valid project names are `projects`, `results`, `risks`.
  """

  alias Alice.Conn
  import AclIvanBot.Constants
  import AclIvanBot.DateHelper
  import AclIvanBot.Reports
  import AclIvanBot.ReportsHelper
  use Alice.Router

  command ~r/\bguide\b/i, :guide
  command ~r/\breport\b/i, :daily_report
  command ~r/\bwho\s\bcares/i, :who_cares
  command ~r/\byesterday\b/i, :yesterday_report
  route ~r/\bstandup\b\s+(?<term>.+)/i, :standup

  def daily_report(conn) do
    conn
    |> generate_report(today)
    |> reply(conn)
  end

  def guide(conn), do: "templates/guide.eex" |> EEx.eval_file |> reply(conn)

  def standup(conn) do
    response = if valid_project_name?(conn) do
       update_report(conn)
    else
      @valid_project_name_warning
    end

    reply(response, conn)
  end

  def who_cares(conn = %Conn{slack: %{users: users}}) do
    care = conn
    |> users_care_list
    |> Enum.map(fn(user_id) ->
      fetch_name(users, user_id)
    end)

    dont_care = conn
                |> user_dont_care_list
                |> Enum.map(fn(user_id) ->
                  fetch_name(users, user_id)
                end)
                |> Enum.filter(fn(item) ->
                  String.length(item) > 0
                end)

    "templates/care_list.eex"
    |> EEx.eval_file([care: care, dont_care: dont_care])
    |> String.trim_trailing
    |> reply(conn)
  end

  def yesterday_report(conn) do
    conn
    |> generate_report(yesterday)
    |> reply(conn)
  end

  defp users_care_list(conn) do
    projects_list
    |> Enum.map(fn(project_name) ->
      conn
      |> Conn.get_state_for(today, %{})
      |> Map.get(project_name, %{})
      |> Map.keys
    end)
    |> List.flatten
  end

  defp user_dont_care_list(conn) do
    all_user_ids -- users_care_list(conn)
  end
end
