defmodule AclIvanBot.Reports do
  @moduledoc """
  AclIvanBot.Reports contains all functions related to reports handling
  """

  @already_gen_jira_report ~r/- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -/
  @jira_issue_regex ~r/[a-z]+-\d+/i
  @projects ~w(projects results risks)

  alias Alice.Conn
  import AclIvanBot.DateHelper, only: [today: 0]

  def generate_report(conn, state) when state == %{}, do: "Report is empty."
  def generate_report(conn = %Conn{slack: %{users: users}}, state) do
    @projects
    |> Enum.map(fn(project_name) ->
        EEx.eval_file(
          "templates/report.eex",
          [
            project_name: project_name,
            reports: reports_per_project(project_name, users, state, conn)
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
    Enum.member?(@projects, Conn.last_capture(conn))
  end

  defp compute_report(report) do
    report = cond do
      Regex.match?(@already_gen_jira_report, report) -> report
      Regex.match?(@jira_issue_regex, report) -> generate_jira_report(report)
      true -> report
    end

    report |> String.replace(~r/<|>/, "")
  end

  defp fetch_name(users, user) do
    users
    |> get_in([user, :profile, :first_name])
    |> to_string
    |> case do
        "" -> get_in(users, [user, :name])
        name -> name
      end
    |> String.upcase
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

  defp reports_per_project(project_name, users, state, conn) do
    state
    |> Map.get(project_name, %{})
    |> Map.to_list
    |> Enum.map(
      fn({user, report}) ->
        computed_report = compute_report(report)
        new_state = updated_state(
          conn,
          %{report: computed_report, project_name: project_name}
        )
        Conn.put_state_for(conn, today, new_state)

        """
        *#{fetch_name(users, user)}:*
        #{computed_report}
        """
      end)
  end

  defp report_thank(conn) do
    "Thank you for your report, #{Conn.at_reply_user(conn)}"
  end

  defp updated_state(conn = %Conn{message: %{user: user_id, text: report}}, options \\ %{}) do
    report = options[:report] || report
    project_name = options[:project_name] || conn |> Conn.last_capture |> String.downcase
    state_by_project = conn
                        |> Conn.get_state_for(today, %{})
                        |> Map.put_new(project_name, %{})
                        |> Map.get(project_name, %{})
                        |> Map.put(user_id, format_report(report))
    conn
    |> Conn.get_state_for(today, %{})
    |> Map.put(project_name, state_by_project)
  end
end
