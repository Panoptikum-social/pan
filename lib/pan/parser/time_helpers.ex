defmodule Pan.Parser.MyDateTime do
  def now() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end

  def in_the_future?(nil), do: false
  def in_the_future?(naive_date_time) do
    NaiveDateTime.compare(naive_date_time, now()) == :gt
  end

  def in_the_past?(nil), do: false
  def in_the_past?(naive_date_time) do
    NaiveDateTime.compare(naive_date_time, now()) == :lt
  end

  def time_shift(naive_date_time, seconds: seconds) do
    NaiveDateTime.add(naive_date_time, seconds, :second)
  end
  def time_shift(naive_date_time, minutes: minutes) do
    NaiveDateTime.add(naive_date_time, 60 * minutes, :second)
  end
  def time_shift(naive_date_time, hours: hours) do
    NaiveDateTime.add(naive_date_time, 3_600 * hours, :second)
  end
  def time_shift(naive_date_time, days: days) do
    NaiveDateTime.add(naive_date_time, 86_400 * days, :second)
  end

  def time_diff(first_date_time, second_date_time, :minutes) do
    NaiveDateTime.diff(first_date_time, second_date_time) / 60
    |> round()
  end
  def time_diff(first_date_time, second_date_time, :hours) do
    NaiveDateTime.diff(first_date_time, second_date_time) / 3_600
    |> round()
  end
  def time_diff(first_date_time, second_date_time, :days) do
    NaiveDateTime.diff(first_date_time, second_date_time) / 86_400
    |> round()
  end
end
