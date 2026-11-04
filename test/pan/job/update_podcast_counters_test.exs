defmodule Pan.Job.UpdatePodcastCountersTest do
  use ExUnit.Case, async: true

  alias Pan.Job.UpdatePodcastCounters

  defp ms_until(utc_string) do
    {:ok, now, 0} = DateTime.from_iso8601(utc_string)
    UpdatePodcastCounters.ms_until_next_run(now)
  end

  defp hours(h), do: round(h * 60 * 60 * 1000)

  test "before 02:22 Vienna time runs the same night" do
    # 2026-11-04 00:22 CET = 23:22 UTC the day before
    assert ms_until("2026-11-03T23:22:00Z") == hours(2)
  end

  test "after 02:22 Vienna time runs the next night" do
    # 12:22 CET → next run 2026-11-05 02:22 CET
    assert ms_until("2026-11-04T11:22:00Z") == hours(14)
  end

  test "exactly at 02:22 schedules the next night, not a second run" do
    assert ms_until("2026-11-04T01:22:00Z") == hours(24)
  end

  test "summer time: 02:22 CEST is 00:22 UTC" do
    # 2026-07-01 12:22 CEST → 2026-07-02 02:22 CEST
    assert ms_until("2026-07-01T10:22:00Z") == hours(14)
  end

  test "spring forward: 02:22 doesn't exist, runs at 03:00 CEST" do
    # 2027-03-28 00:00 CET (23:00 UTC) → 03:00 CEST (01:00 UTC)
    assert ms_until("2027-03-27T23:00:00Z") == hours(2)
  end

  test "fall back: 02:22 exists twice, runs at the first one (CEST)" do
    # 2026-10-25 00:00 CEST (22:00 UTC) → 02:22 CEST (00:22 UTC)
    assert ms_until("2026-10-24T22:00:00Z") == hours(2 + 22 / 60)
  end
end
