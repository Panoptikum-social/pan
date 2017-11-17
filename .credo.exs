# config/.credo.exs
%{
  configs: [
    %{
      name: "default",
      color: true,
      files: %{
        included: ["lib/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      checks: [
        # disable some checks, for now(?)
        {Credo.Check.Refactor.PipeChainStart, false},
        {Credo.Check.Readability.ModuleDoc, false}
      ]
    }
  ]
}
