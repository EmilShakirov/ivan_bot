defmodule Alice.Handlers.Standup do
  @moduledoc """
  Alice.Handlers.Standup is a slack handler for managing incoming slack bot messages
  """

  @valid_project_name_warning """
  Please enter valid command: `standup %PROJECT_NAME%`
  Valid project names are `projects`, `results`, `risks`.
  """

  alias Alice.Conn
  alias Alice.StateBackends
  import AclIvanBot.DateHelper
  import AclIvanBot.Reports
  use Alice.Router

  command ~r/\bguide\b/i, :guide
  command ~r/\breport\b/i, :daily_report
  command ~r/\byesterday\b/i, :yesterday_report
  route ~r/\bstandup\b\s+(?<term>.+)/i, :standup

  def daily_report(conn) do
    conn
    |> generate_report(Conn.get_state_for(conn, today, %{}))
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

  def yesterday_report(conn) do
    conn
    |> generate_report(Conn.get_state_for(conn, yesterday, %{}))
    |> reply(conn)
  end
end
