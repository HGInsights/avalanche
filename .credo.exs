%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      requires: [],
      strict: false,
      color: true,
      checks: [
        # enabled extra Credo checks
        {Credo.Check.Readability.AliasAs, []},
        {Credo.Check.Readability.SinglePipe, [exit_status: 0]},
        {Credo.Check.Readability.StrictModuleLayout, order: ~w/
          shortdoc
          moduledoc
          behaviour
          use
          import
          alias
          require
          module_attribute
          defstruct
          opaque
          type
          typep
          callback
          macrocallback
          optional_callbacks
          public_guard
          public_macro
          public_fun
          impl
          private_fun
        /a, ignore: ~w/
          private_macro
          callback_impl
          private_guard
          module
        /a},

        # modified checks
        {Credo.Check.Design.TagTODO, [exit_status: 0]},
        {Credo.Check.Design.AliasUsage,
         [priority: :low, if_nested_deeper_than: 4, if_called_more_often_than: 3]},

        # disabled checks
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Readability.MaxLineLength, false},
        {Credo.Check.Readability.Specs, false},
      ]
    }
  ]
}
