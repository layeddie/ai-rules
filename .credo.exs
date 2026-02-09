import Config

config :credo,
  checks: [
    {Credo.Check.Readability.ModuleDoc, false},
    {Credo.Check.Readability.MaxLineLength, max_length: 120},
    {Credo.Check.Design.TagTODO, false},
    {Credo.Check.Design.TagFIXME, false},
    {Credo.Check.Readability.LargeNumbers, false},
    {Credo.Check.Warning.IExPry, false},
    {Credo.Check.Warning.IoInspect, false},
    {Credo.Check.Warning.UnusedEnumOperation, false},
    {Credo.Check.Warning.UnusedKeywordOperation, false},
    {Credo.Check.Warning.UnusedListOperation, false},
    {Credo.Check.Warning.UnusedPathOperation, false},
    {Credo.Check.Warning.UnusedRegexOperation, false},
    {Credo.Check.Warning.UnusedStringOperation, false},
    {Credo.Check.Warning.UnusedTupleOperation, false}
  ]
