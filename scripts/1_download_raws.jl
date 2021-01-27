## --------------------------------------------------------------------
import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

import Chemostat_Human1
const H1 = Chemostat_Human1

## --------------------------------------------------------------------
# Downloading
if isdir(H1.HUMAN1_PUBLICATION_RAW_DATA_DIR)
    println(relpath(H1.HUMAN1_PUBLICATION_RAW_DATA_DIR), " already exist, to force a re-unzip delete the folder")
elseif isfile(H1.HUMAN1_PUBLICATION_ZIP_FILE)
    println(relpath(H1.HUMAN1_PUBLICATION_ZIP_FILE), " already exist, to force a re-download delete it")
    run(`unzip $(H1.HUMAN1_PUBLICATION_ZIP_FILE) -d $(H1.RAW_DATA_DIR)`)
else
    println("downloading from: ", H1.HUMAN1_PUBLICATION_ZENODO_LINK)
    run(`curl $(H1.HUMAN1_PUBLICATION_ZENODO_LINK) --output $(H1.HUMAN1_PUBLICATION_ZIP_FILE)`)
    run(`unzip $(H1.HUMAN1_PUBLICATION_ZIP_FILE) -d $(H1.RAW_DATA_DIR)`)
end
!isdir(H1.HUMAN1_PUBLICATION_RAW_DATA_DIR) && 
    error("$(H1.HUMAN1_PUBLICATION_RAW_DATA_DIR) not found after download && unzip!!!")
println(relpath(H1.HUMAN1_PUBLICATION_RAW_DATA_DIR), " ready!!!")
flush(stdout)
flush(stderr)