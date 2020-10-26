module Chemostat_Human1

    import Chemostat
    include("Utils/Utils.jl")

    function __init__()
        _make_dirs()
    end
end
