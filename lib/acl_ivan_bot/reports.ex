defmodule AclIvanBot.Reports do
  @moduledoc """
  AclIvanBot.Reports contains all functions related to reports handling
  """

  @projects ~w(projects results risks)

  alias Alice.Conn
  import AclIvanBot.DateHelper, only: [today: 0]

  def generate_report(conn = %Conn{slack: %{users: users}}, state) do
    @projects
    |> Enum.map(fn(project_name) ->
        EEx.eval_file(
          "templates/report.eex",
          [
            project_name: project_name,
            reports: reports_per_project(project_name, users, state)
          ]
        )
    end)
    |> Enum.join("\n")
    |> String.trim_trailing
  end

  def format_report(report) do
    report
    |> String.replace(~r/<|>/, "")
    |> String.replace(~r/^@\w+\s/, "")
    |> String.replace(~r/standup\s+\w+\n/i, "")
  end

  def update_report(conn) do
    conn
    |> Conn.put_state_for(today, updated_state(conn))
    |> report_thank
  end

  def valid_project_name?(conn) do
    Enum.member?(@projects, Conn.last_capture(conn))
  end

  defp fetch_name(users, user) do
    users
    |> get_in([user, :profile, :first_name])
    |> case do
        "" -> get_in(users, [user, :name])
        nil -> get_in(users, [user, :name])
        name -> name
      end
    |> String.upcase
  end

  defp updated_state(conn = %Conn{message: %{user: user_id, text: report}}) do
    project_name = conn |> Conn.last_capture |> String.downcase
    state_by_project = conn
                        |> Conn.get_state_for(today, %{})
                        |> Map.put_new(project_name, %{})
                        |> Map.get(project_name, %{})
                        |> Map.put(user_id, format_report(report))

    conn
    |> Conn.get_state_for(today, %{})
    |> Map.put(project_name, state_by_project)
  end

  defp reports_per_project(project_name, users, state) do
      state
      |> Map.get(project_name, %{})
      |> Map.to_list
      |> Enum.map(
        fn({user, report}) ->
          """
          *#{fetch_name(users, user)}:*
          #{String.replace(report, ~r/<|>/, "")}
          """
        end)
  end

  defp report_thank(conn) do
    "Thank you for your report, #{Conn.at_reply_user(conn)}"
  end
end
