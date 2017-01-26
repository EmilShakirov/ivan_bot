defmodule IvanBot.Reports do
  @moduledoc """
  Contains all functions related to reports handling
  """

  alias Alice.Conn
  import IvanBot.{Constants, DateHelper, ReportsHelper}

  def get_users_report(conn = %Conn{message: %{user: user_id}}) do
    conn |> Conn.get_state_for(today) |> get_in([project_name_from_conn(conn), user_id])
  end

  def generate_report(conn, time) do
    projects_list
    |> Enum.map(fn(project_name) ->
        EEx.eval_file(
          "templates/report.eex",
          [
            project_name: project_name,
            reports: reports_per_project(conn, project_name, time)
          ]
        )
    end)
    |> Enum.join(new_line)
    |> String.trim
  end

  def report_thank(report, conn) do
    """
    Thank you for your report, #{Conn.at_reply_user(conn)}

    Here it is, please check it out:
    #{report}
    """
  end

  def update_report(conn) do
    conn |> parse_user_input |> put_project_state(conn)
  end

  def valid_project_name?(conn) do
    Enum.member?(projects_list, project_name_from_conn(conn))
  end

  defp decorate_report(report) do
    report = report
            |> String.replace(~r/<|>/, "")
            |> String.replace(~r/^@\w+\s/, "")
            |> String.replace(~r/standup\s+\w+\n/i, "")

    if Regex.match?(jira_issue_regex, report), do: report = generate_jira_report(report)

    report
  end

  defp fetch_ticket_details(issue_number) do
    case Jira.API.ticket_details(issue_number) do
      %{"fields" => fields} ->
        %{"summary" => summary, "status" => %{"name" => status}} = fields
        {:ok, status, summary}
      %{"errorMessages" => errorMessages} -> {:error, errorMessages}
    end
  end

  defp generate_jira_report(report) do
    report
    |> String.split([new_line], trim: true)
    |> Enum.with_index(1)
    |> Enum.map(&(Task.async(fn -> represent_jira_issue(&1) end)))
    |> Enum.map(&Task.await/1)
    |> Enum.filter(fn(item) -> String.length(item) > 0 end)
    |> Enum.join(new_line)
  end

  defp new_project_state(report, conn = %Conn{message: %{user: user_id}}) do
    conn
    |> Conn.get_state_for(today, empty_team_report)
    |> put_in([project_name_from_conn(conn), user_id], report)
  end

  defp parse_user_input(conn = %Conn{message: %{text: raw_report}}) do
    raw_report |> decorate_report |> new_project_state(conn)
  end

  defp project_name_from_conn(conn) do
    conn |> Conn.last_capture |> String.downcase
  end

  defp put_project_state(project_state, conn) do
    conn |> Conn.put_state_for(today, project_state)
  end

  defp represent_jira_issue({";", _index}), do: ""
  defp represent_jira_issue({",", _index}), do: ""
  defp represent_jira_issue({"", _index}), do: ""
  defp represent_jira_issue({issue, index}) do
    [number | custom_status] = issue |> String.trim |> String.split([";"], trim: true)

    case fetch_ticket_details(number) do
      {:ok, status, summary} ->
        if length(custom_status) > 0, do: status = List.first(custom_status)

        EEx.eval_file(
          "templates/jira_issue.eex",
          [
            index: index,
            issue: number,
            link: "#{Application.get_env(:jira, :host)}/browse/#{number}",
            status: status,
            summary: summary
          ])
      {:error, _} ->
        EEx.eval_file("templates/unknown_issue.eex", [index: index, issue: number])
    end
  end

  defp reports_per_project(conn = %Conn{slack: %{users: users}}, project_name, time) do
    conn
    |> Conn.get_state_for(time, %{})
    |> Map.get(project_name, %{})
    |> Map.to_list
    |> Enum.map(
      fn({user_id, report}) ->
        """
        *#{fetch_name(users, user_id)}:*
        #{report}
        """
      end)
  end
end
