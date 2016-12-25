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
  import AclIvanBot.DateHelper
  import ExUnit.TestHelpers

  defp conn do
    %Conn{
      message: %{user: @user_id, text: "test", channel: :channel, captures: ["projects"]},
      slack: %{users: %{@user_id => %{name: "Ivan", id: "ivan"}}},
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
    test "generates daily report", state do
      report = "daily_report.txt" |> load_fixture |> String.trim_trailing
      Standup.daily_report(state[:conn])

      assert_received {:msg, ^report}
    end
  end

  describe "yesterday_report/1" do
    test "generates yesterday report", state do
      report = "yesterday_report.txt" |> load_fixture |> String.trim_trailing
      Standup.yesterday_report(state[:conn])

      assert_received {:msg, ^report}
    end
  end

  describe "standup/1" do
    test "says thanks after receiving standup report", state do
      thanks = "Thank you for your report, <@ivan>"
      Standup.standup(state[:conn])

      assert_received {:msg, ^thanks}
    end
  end
end
