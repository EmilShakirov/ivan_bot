require IEx;

defmodule Alice.Handlers.Standup do
  @moduledoc """
  Alice.Handlers.Standup is a slack handler for managing incoming slack bot messages
  """

  @projects ~w(projects results risks)

  use Alice.Router
  use Timex

  alias Alice.Conn
  alias Alice.StateBackends

  command ~r/\breport\b/i, :daily_report
  command ~r/\bstandup\b\s+(?<term>.+)/i, :standup
  route ~r/\bstandup\b\s+(?<term>.+)/i, :standup

  def daily_report(conn = %Conn{slack: %{users: users}}) do
    @projects
    |> Enum.map(fn(project_name) ->
        EEx.eval_file(
          "templates/report.eex",
          [
            project_name: project_name,
            reports: reports_per_project(project_name, conn)
          ]
        )
    end)
    |> Enum.join("\n")
    |> reply(conn)
  end

  def notify do
    """
    _Please stand up_
    """
    |> Slack.send_message(Application.get_env(:alice, :room))
  end

  def standup(conn = %Conn{message: %{user: user_id, text: report}}) do
    updated_report =  conn
                      |> Conn.last_capture
                      |> String.downcase
                      |> update_report(user_id, report, conn)

    conn
    |> put_state(timestamp(), updated_report)
    |> report_thank
    |> reply(conn)
  end

  defp current_report(conn), do: get_state(conn, timestamp(), %{})

  defp format_report(report) do
    report
    |> String.replace(~r/standup\s+\w+\n/i, "")
    |> String.replace(~r/<|>/, "")
  end

  defp reports_per_project(project_name, conn = %Conn{slack: %{users: users}}) do
    conn
      |> current_report
      |> Map.get(project_name, %{})
      |> Map.to_list
      |> Enum.map(
        fn({user, report}) ->
          name = get_in(users, [user, :profile, :real_name_normalized])
          if String.first(name) == nil, do: name = get_in(users, [user, :name])

          """
          *#{name}*
          #{String.replace(report, ~r/<|>/, "")}
          """
        end)
  end

  defp report_thank(conn) do
    "Thank you for your report, #{Conn.at_reply_user(conn)}"
  end

  defp timestamp do
    Timex.format!(Timex.today, "%y%m%d", :strftime)
  end

  defp update_report(project_name, user_id, report, conn) do
    state = current_report(conn)
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
