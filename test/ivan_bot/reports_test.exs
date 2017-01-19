defmodule IvanBot.ReportsTest do
  use ExUnit.Case, async: false
  alias Alice.Conn
  import Mock
  import ExUnit.TestHelpers
  import IvanBot.{DateHelper, Reports}

  defp default_conn do
    %Conn{
      message: %{user: "U32FGC7UG", text: "updated report", channel: :channel, captures: ["projects"]},
      slack: %{users:
        %{
          "U32FGC7UG" => %{name: "Michael", id: "michael"}
        },
      },
      state: %{
        today => %{"projects" =>
          %{"U32FGC7UG" => "XD-666;Go go PR, Continue;aa!bb@;;;;,\nXD-333;WIP\n\n;\n,"}
        },
      }
    }
  end

  defp fake_ticket_details(num) do
    %{"fields" => %{"summary" => "#{num} SUMMARY", "status" => %{"name" => "WIP"}}}
  end

  defp failure_jira_response(_num) do
      %{"errorMessages" => "Issue not found"}
  end

  setup do
    {
      :ok,
      conn: default_conn,
      fake_ticket_details: &fake_ticket_details/1,
      failure_jira_response: &failure_jira_response/1,
    }
  end

  describe "#generate_report/2" do
    test_with_mock "generates regular report when issue exists",
      %{conn: conn, fake_ticket_details: fake_tickets_details},
      Jira.API, [], [ticket_details: fake_tickets_details] do
        report = "generate_report/ok_jira_report.txt" |> load_fixture |>  String.trim_trailing
        assert report == generate_report(conn, today)
    end

    test_with_mock "generates report as is when issue not found",
      %{conn: conn, failure_jira_response: failure_jira_response},
      Jira.API, [], [ticket_details: failure_jira_response] do
        report = "generate_report/unknown_jira_report.txt" |> load_fixture |>  String.trim_trailing
        assert report == generate_report(conn, today)
    end
  end

  describe "#update_report/1" do
    test "updates report in Conn state", %{conn: conn} do
      new_conn = update_report(conn)
      new_report = get_in(new_conn.state, [today, "projects", "U32FGC7UG"])
      assert new_report == "updated report"
    end
  end

  describe "#report_thank/1" do
    test "updates report in Conn state", %{conn: conn} do
      assert report_thank(conn) == "Thank you for your report, <@michael>"
    end
  end
end
