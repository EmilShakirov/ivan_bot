defmodule Alice.Handlers.Standup do
  @moduledoc """
  A slack handler for managing incoming slack bot messages
  """

  alias Alice.Conn
  import IvanBot.{Constants, DateHelper, Reports, ReportsHelper}
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
      conn |> update_report |> report_thank
    else
      valid_project_name_warning
    end

    reply(response, conn)
  end

  def who_cares(conn = %Conn{slack: %{users: users}}) do
    get_name = fn(user_id) -> "@#{get_in(users, [user_id, :name])}" end

    care = conn
          |> users_care_list
          |> Enum.map(get_name)
          |> Enum.join(", ")

    dont_care = conn
                |> user_dont_care_list
                |> Enum.map(get_name)
                |> Enum.filter(fn(item) -> !is_nil(item) end)
                |> Enum.filter(fn(item) -> String.length(item) > 1 end)
                |> Enum.join(", ")

    "templates/care_list.eex"
    |> EEx.eval_file([care: care, dont_care: dont_care])
    |> String.trim_leading
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
