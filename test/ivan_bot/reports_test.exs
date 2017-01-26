defmodule IvanBot.ReportsTest do
  use ExUnit.Case, async: false
  alias Alice.Conn
  import Mock
  import ExUnit.TestHelpers
  import IvanBot.{DateHelper, Reports}

  defp default_conn do
    %Conn{
      message: %{user: "U32FGC7UG", text: "PR-888\nGCC-8976; Some Status\n", channel: :channel, captures: ["projects"]},
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
      today: today,
      fake_ticket_details: &fake_ticket_details/1,
      failure_jira_response: &failure_jira_response/1,
    }
  end

  describe "#generate_report/2" do
    test "generate full report for teams", %{conn: conn} do
      report = "generated_report.txt" |> load_fixture |> String.trim

      assert generate_report(conn, today) == report
    end
  end

  describe "#update_report/1" do
    test_with_mock "successfull report update from jira",
      %{conn: conn, fake_ticket_details: fake_ticket_details, today: today},
      Jira.API, [], [ticket_details: fake_ticket_details] do
        %Conn{state: %{^today => %{"projects" => %{"U32FGC7UG" => updated_report}}}} = update_report(conn)
        ok_report = "update_report/ok_jira_report.txt" |> load_fixture

        assert updated_report == ok_report
    end

    test_with_mock "failure report update from jira",
      %{conn: conn, failure_jira_response: failure_jira_response, today: today},
      Jira.API, [], [ticket_details: failure_jira_response] do
        %Conn{state: %{^today => %{"projects" => %{"U32FGC7UG" => updated_report}}}} = update_report(conn)
        fail_report = "update_report/fail_jira_report.txt" |> load_fixture

        assert updated_report == fail_report
    end
  end

  describe "#report_thank/1" do
    test "updates report in Conn state", %{conn: conn} do
      response = "report_thank.txt" |> load_fixture

      assert report_thank("Report", conn) == response
    end
  end
end
