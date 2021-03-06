defmodule IvanBot.Constants do
  @moduledoc false

  defmacro default_time_format do
    quote do: "%y%m%d"
  end

  defmacro projects_list do
    quote do: ~w(projects results risks)
  end

  defmacro projects_ids do
    quote do: ~w(U32FGC7UG U334YACBV U33T52M5M U421XV5RA)
  end

  defmacro results_ids do
    quote do: ~w(U32FL6RS4 U418ZRFCH)
  end

  defmacro risks_ids do
    quote do: ~w(U3356MZGT U33TFH5ST)
  end

  defmacro all_user_ids do
    quote do: unquote(projects_ids ++ results_ids ++ risks_ids)
  end

  defmacro valid_project_name_warning do
    quote do: """
    Please enter valid command: `standup %PROJECT_NAME%`
    Valid project names are `projects`, `results`, `risks`.
    """
  end

  defmacro jira_issue_regex do
    quote do: ~r/[a-z]+-\d+/i
  end

  defmacro new_line do
    quote do: "\n"
  end

  defmacro empty_team_report do
    quote do: %{"projects" => %{}, "results" => %{}, "risks" => %{}}
  end
end
