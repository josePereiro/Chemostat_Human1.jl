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
pkg"add https://github.com/josePereiro/UtilsJL.git#v0.2.3"
pkg"add https://github.com/josePereiro/Chemostat#v0.7.0"
pkg"instantiate"
pkg"build"