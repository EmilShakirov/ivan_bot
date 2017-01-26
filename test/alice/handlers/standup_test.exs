defmodule FakeSlack do
  def send_message(text, :channel, %{}) do
    send(self, {:msg, text})
  end
end


defmodule Alice.Handlers.StandupTest do
  @user_id "U123456"

  use ExUnit.Case, async: true
  alias Alice.Handlers.Standup
  alias Alice.Conn
  import IvanBot.DateHelper
  import ExUnit.TestHelpers

  defp conn do
    %Conn{
      message: %{user: @user_id, text: "test", channel: :channel, captures: ["projects"]},
      slack: %{users:
        %{
          @user_id => %{name: "Ivan", id: "ivan"},
          "U32FGC7UG" => %{name: "Michael", id: "michael"}
        },
      },
      state: %{
        today => %{"projects" => %{@user_id => "report"}},
        yesterday => %{"projects" => %{@user_id => "yesterday's report"}}
      }
    }
  end

  setup_all do
    {:ok, conn: conn}
  end

  describe "guide/1" do
    test "replies with guide", state do
      guide = EEx.eval_file("templates/guide.eex")
      Standup.guide(state[:conn])

      assert_received {:msg, ^guide}
    end
  end

  describe "daily_report/1" do
    test "generates daily report", %{conn: conn} do
      report = "daily_report.txt" |> load_fixture |> String.trim_trailing
      Standup.daily_report(conn)

      assert_received {:msg, ^report}
    end
  end

  describe "yesterday_report/1" do
    test "generates yesterday report", %{conn: conn} do
      report = "yesterday_report.txt" |> load_fixture |> String.trim_trailing
      Standup.yesterday_report(conn)

      assert_received {:msg, ^report}
    end
  end

  describe "standup/1" do
    test "says thanks after receiving standup report", %{conn: conn} do
      thanks = "Thank you for your report, <@ivan>\n\nHere it is, please check it out:\ntest\n"
      Standup.standup(conn)

      assert_received {:msg, ^thanks}
    end
  end

  describe "who_cares/1" do
    test "renders senders list", %{conn: conn} do
      list = "care_list.txt" |> load_fixture |> String.trim_trailing
      Standup.who_cares(conn)

      assert_received {:msg, ^list}
    end
  end
end
