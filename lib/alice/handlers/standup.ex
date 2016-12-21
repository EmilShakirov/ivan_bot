defmodule Alice.Handlers.Standup do
  import AclIvanBot.DateHelper

  @moduledoc """
  Alice.Handlers.Standup is a slack handler for managing incoming slack bot messages
  """

  @projects ~w(projects results risks)

  use Alice.Router

  alias Alice.Conn
  alias Alice.StateBackends


  command ~r/\breport\b/i, :daily_report
  command ~r/\byesterday\b/i, :yesterday_report
  command ~r/\bstandup\b\s+(?<term>.+)/i, :standup
  route ~r/\bstandup\b\s+(?<term>.+)/i, :standup

  def daily_report(conn), do: generate_report(conn, today) |> reply(conn)

  def notify do
    """
    _Please stand up_
    """
    |> Slack.send_message(Application.get_env(:alice, :room))
  end

  def standup(conn) do
    if Enum.member?(@projects, Conn.last_capture(conn)) do
       successfull_report(conn)
    else
      """
      Please enter valid command: `standup %PROJECT_NAME%`
      Valid project names are `projects`, `results`, `risks`.
      """
    end
    |> reply(conn)
  end

  def yesterday_report(conn), do: generate_report(conn, yesterday) |> reply(conn)

  defp successfull_report(conn = %Conn{message: %{user: user_id, text: report}}) do
    updated_report = conn
                      |> Conn.last_capture
                      |> String.downcase
                      |> update_report(user_id, report, conn)

    conn
    |> put_state(today(), updated_report)
    |> report_thank
  end

  defp generate_report(conn, time) do
    @projects
    |> Enum.map(fn(project_name) ->
        EEx.eval_file(
          "templates/report.eex",
          [
            project_name: project_name,
            reports: reports_per_project(project_name, conn, time)
          ]
        )
    end)
    |> Enum.join("\n")
  end

  defp format_report(report) do
    report
    |> String.replace(~r/<|>/, "")
    |> String.replace(~r/^@\w+\s/, "")
    |> String.replace(~r/standup\s+\w+\n/i, "")
  end

  defp reports_per_project(project_name, conn = %Conn{slack: %{users: users}}, time) do
    conn
      |> get_state(time, %{})
      |> Map.get(project_name, %{})
      |> Map.to_list
      |> Enum.map(
        fn({user, report}) ->
          name = get_in(users, [user, :profile, :real_name_normalized])
          if String.first(name) == nil, do: name = get_in(users, [user, :name])

          """
          *#{name}:*
          #{String.replace(report, ~r/<|>/, "")}
          """
        end)
  end

  defp report_thank(conn) do
    "Thank you for your report, #{Conn.at_reply_user(conn)}"
  end

  defp update_report(project_name, user_id, report, conn) do
    state = get_state(conn, today, %{})
    project_name = String.downcase(project_name)
    by_project = state
                  |> Map.put_new(project_name, %{})
                  |> Map.get(project_name, %{})

    Map.put(
      state,
      project_name,
      Map.put(by_project, user_id, format_report(report))
    )
  end
end
