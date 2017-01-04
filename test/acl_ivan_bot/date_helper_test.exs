defmodule IvanBot.DateHelperTest do
  use ExUnit.Case
  doctest IvanBot.DateHelper

  import Mock

  alias IvanBot.DateHelper

  describe "today/0" do
    test "replies with formatted today date" do
      with_mock(Timex, [:passthrough], [today: fn() -> ~D[2016-12-27] end]) do
        assert "161227" == DateHelper.today
      end
    end
  end

  describe "yesterday/0" do
    test "replies with formatted previous day" do
      with_mock(Timex, [:passthrough], [today: fn() -> ~D[2016-12-27] end]) do
        assert "161226" == DateHelper.yesterday
      end
    end

    test "replies with formatted previous day exluding weekend" do
      with_mock(Timex, [:passthrough], [today: fn() -> ~D[2016-12-26] end]) do
        assert "161223" == DateHelper.yesterday
      end
    end
  end
end
