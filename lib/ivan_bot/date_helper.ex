defmodule IvanBot.DateHelper do
  @moduledoc ~S"""
  Helper functions related to date and time
  """

  import IvanBot.Constants

  use Timex

  @doc ~s"""
    Returns current date formatted as #{default_time_format}
  """
  @spec today() :: String.t
  def today do
    default_format!(Timex.today)
  end

  @doc ~s"""
  Returns returns previous work day formatted as #{default_time_format}

  E.g. will return friday if today is monday
  """
  @spec yesterday() :: String.t
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
    Timex.format!(time, default_time_format, :strftime)
  end
end
