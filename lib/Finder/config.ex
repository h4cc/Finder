defmodule Finder.Config do

    @doc "Configuration. Will be evaluated in find/2."
    # This record is held public, so it could be stored and manipulated externally.
    defstruct mode: :all, stats: false, file_endings: [], file_regexes: [], dir_regexes: []

end