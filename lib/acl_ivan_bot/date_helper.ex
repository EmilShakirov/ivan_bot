defmodule AclIvanBot.DateHelper do
  use Timex

  def today do
    Timex.format!(Timex.today, "%y%m%d", :strftime)
  end

  def yesterday do
    case Timex.weekday(Timex.today) do
      1 -> Timex.shift(Timex.today, days: -3)
      _ -> Timex.shift(Timex.today, days: -1)
    end
    |> Timex.format!("%y%m%d", :strftime)
  end
end
