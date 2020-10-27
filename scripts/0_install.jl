try import DrWatson
catch
    import Pkg
    Pkg.add("DrWatson")
end
import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

## ------------------------------------------------------------------------
# Install unregistered packages
using Pkg
try
    pkg"rm Chemostat"
    pkg"rm UtilsJL"
catch; end
pkg"add https://github.com/josePereiro/UtilsJL.git#master"
pkg"add https://github.com/josePereiro/Chemostat#e226e31"
pkg"instantiate"
pkg"build"