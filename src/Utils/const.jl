const HUMAN1_PUBLICATION_PROJ_NAME = "Human1_Publication_Data_Scripts"
const HUMAN1_PROBLICATION_ZENODO_LINK = "https://zenodo.org/record/3583004/files/Human1_Publication_Data_Scripts.zip?download=1"

# Some usful iders
const BIOMASS_IDER = "biomass_human"
const COST_IDER = "prot_pool_exchange"
const ATPM_IDER = "HMR_3964";
const EXCH_SUBSYS_HINT = "Exchange/demand"

# Human1
const CELL_NAMES = ["HS_578T", "RPMI_8226", "HT29", "MALME_3M", "SR",
               "UO_31", "MDMAMB_231", "HOP62", "NCI_H226", "HOP92", "O_786"];
const CONSTRAINTS_NAMES = ["media", "glucose", "L-lactate", "threonine"];
const CONSTRAINTS_LEVELS = [0, 1, 2, 3]

# Common constants
const MAX_ABS_BOUND = 100
const MAX_CONC = 99999 # Inf conc means that the metabolite will be never limiting the growth
const ZEROTH = 1e-8

const MODEL_TYPE_KEY = :model
const MODEL_TYPE_SUFFIX = "__Model"
const EC_MODEL_TYPE_KEY = :ecModel
const EC_MODEL_TYPE_SUFFIX = "__ecModel"
