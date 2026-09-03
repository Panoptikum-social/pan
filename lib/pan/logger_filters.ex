defmodule Pan.LoggerFilters do
  @moduledoc """
  `:logger` primary filters for noise that's genuinely harmless — real
  errors still need to reach the console; this is specifically for
  diagnostics that duplicate information the app already logs properly
  elsewhere.
  """

  # xmerl (which Quinn.parse/1 wraps directly, see deps/quinn) logs this
  # unconditionally via the legacy error_logger:error_msg/2 API whenever it
  # hits malformed XML — *before* it raises exit({:fatal, ...}), regardless
  # of whether that exit gets caught downstream. In this app it already is:
  # Pan.Updater.RssFeed.xml_to_map/2 wraps Quinn.parse/1 in
  # `catch :exit, {:fatal, error} -> {:error, ...}`, and that error already
  # gets logged properly (with podcast id/title context) via
  # Pan.Updater.Podcast.handle_message/3. So this raw report — no
  # stacktrace, no module/mfa metadata, just "<line>- fatal: <reason>" —
  # only ever duplicates a failure the app already reports clearly, while
  # reading like an uncaught crash.
  #
  # Deliberately narrow: only these specific, understood reasons, each
  # verified live via Tidewave (reproduced against real malformed-XML
  # input, exact event shape checked) before adding it — see backlog.md/
  # memory. xmerl's other ?fatal reasons (there are dozens, see
  # xmerl_scan.erl) stay visible; not individually verified as similarly
  # redundant.
  @doc false

  # A stray "]]>" outside a real CDATA block.
  def silence_xmerl_fatal(
        %{
          msg:
            {:report,
             %{
               label: {:error_logger, :error_msg},
               format: ~c"~p- fatal: ~p~n",
               args: [_line, :unexpected_cdata_end]
             }}
        },
        _extra
      ) do
    :stop
  end

  # The same attribute name (e.g. a duplicated xmlns:itunes) declared
  # twice on one element.
  def silence_xmerl_fatal(
        %{
          msg:
            {:report,
             %{
               label: {:error_logger, :error_msg},
               format: ~c"~p- fatal: ~p~n",
               args: [_line, {:error, {:unique_att_spec_required, _name}}]
             }}
        },
        _extra
      ) do
    :stop
  end

  def silence_xmerl_fatal(event, _extra), do: event
end
