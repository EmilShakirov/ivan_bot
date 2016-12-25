defmodule AclIvanBot.DateHelper do
  @moduledoc """
  AclIvanBot.DateHelper contains helper functions related to date and time
  """

  @default_format_schema "%y%m%d"

  use Timex

  def today do
    default_format!(Timex.today)
  end

  def yesterday do
    Timex.today
    |> Timex.weekday
    |> case do
      1 -> Timex.shift(Timex.today, days: -3)
      _ -> Timex.shift(Timex.today, days: -1)
    end
    |> default_format!
  end

  defp default_format!(time) do
    Timex.format!(time, @default_format_schema, :strftime)
  end
end
