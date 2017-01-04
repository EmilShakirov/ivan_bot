defmodule IvanBot.Reports do
  @moduledoc """
  Contains all functions related to reports handling
  """

  @already_gen_jira_report ~r/- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -/
  @jira_issue_regex ~r/[a-z]+-\d+/i

  alias Alice.Conn
  import IvanBot.DateHelper, only: [today: 0]
  import IvanBot.Constants
  import IvanBot.ReportsHelper

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
    |> Enum.join("\n")
    |> String.trim_trailing
  end

  def update_report(conn) do
    conn
    |> Conn.put_state_for(today, updated_state(conn))
    |> report_thank
  end

  def valid_project_name?(conn) do
    Enum.member?(projects_list, last_capture(conn))
  end

  defp last_capture(conn) do
    conn |> Conn.last_capture |> String.downcase
  end

  defp decorate_report(report) do
    report = cond do
      Regex.match?(@already_gen_jira_report, report) -> report
      Regex.match?(@jira_issue_regex, report)
        && !Regex.match?(~r/browse\//, report) -> generate_jira_report(report)
      true -> report
    end

    report |> String.replace(~r/<|>/, "")
  end

  defp format_report(report) do
    report
    |> String.replace(~r/<|>/, "")
    |> String.replace(~r/^@\w+\s/, "")
    |> String.replace(~r/standup\s+\w+\n/i, "")
  end

  defp generate_jira_report(report) do
    report
    |> String.split([" ", ","], trim: true)
    |> Enum.with_index(1)
    |> Enum.map(&(Task.async(fn -> represent_jira_issue(&1) end)))
    |> Enum.map(&Task.await/1)
    |> Enum.join("\n")
  end

  defp represent_jira_issue({issue, index}) do
    %{"fields" => %{
        "summary" => summary,
        "status" => %{"name" => status}
      }
    } = Jira.API.ticket_details(issue)

    EEx.eval_file(
      "templates/jira_issue.eex",
      [
        index: index,
        issue: issue,
        link: "#{Application.get_env(:jira, :host)}/browse/#{issue}",
        status: status,
        summary: summary
      ])
  end

  defp reports_per_project(conn = %Conn{slack: %{users: users}}, project_name, time) do
    conn
    |> Conn.get_state_for(time, %{})
    |> Map.get(project_name, %{})
    |> Map.to_list
    |> Enum.map(
      fn({user_id, report}) ->
        decorated_report = decorate_report(report)
        new_state = updated_state(
          conn,
          %{
            project_name: project_name,
            report: decorated_report,
            time: time,
            user_id: user_id
          })
        Conn.put_state_for(conn, time, new_state)

        """
        *#{fetch_name(users, user_id)}:*
        #{decorated_report}
        """
      end)
  end

  defp report_thank(conn), do: "Thank you for your report, #{Conn.at_reply_user(conn)}"

  defp updated_state(conn = %Conn{message: %{user: user_id, text: report}}, options \\ %{}) do
    project_name = options[:project_name] || last_capture(conn)
    report = options[:report] || report
    time = options[:time] || today
    user_id = options[:user_id] || user_id

    state_by_project = conn
                        |> Conn.get_state_for(time, %{})
                        |> Map.put_new(project_name, %{})
                        |> Map.get(project_name, %{})
                        |> Map.put(user_id, format_report(report))
    conn
    |> Conn.get_state_for(time, %{})
    |> Map.put(project_name, state_by_project)
  end
end
