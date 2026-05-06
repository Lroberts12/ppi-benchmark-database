# Protein-Protein Interaction Database ETL Pipeline
# Author: Lindsay Roberts
# Purpose: Build a normalized SQLite database from Protein-Protein Docking Benchmark v5.5

library(readxl)
library(DBI)
library(RSQLite)
library(dplyr)
library(stringr)
library(tidyr)

# -----------------------------
# File paths
# -----------------------------
excel_path <- "data/Table_BM5.5.xlsx"
db_path <- "database/ppi_benchmark_FULL.db"
schema_path <- "database/schema.sql"

# -----------------------------
# Extract
# -----------------------------
raw <- read_excel(excel_path, skip = 2)

# -----------------------------
# Transform
# -----------------------------
bench <- raw %>%
  mutate(
    difficulty_level = case_when(
      str_detect(Complex, "Rigid") ~ "rigid",
      str_detect(Complex, "Medium") ~ "medium",
      str_detect(Complex, "Difficult") ~ "difficult",
      TRUE ~ NA_character_
    )
  ) %>%
  fill(difficulty_level, .direction = "down") %>%
  filter(!is.na(Cat.)) %>%
  rename(
    complex_id = Complex,
    type_code = Cat.,
    pdbid_1 = `PDB ID 1`,
    protein_1 = `Protein 1`,
    pdbid_2 = `PDB ID 2`,
    protein_2 = `Protein 2`,
    rmsd = `I-RMSD (Å)`,
    interface_surface_area = `ΔASA(Å2)`,
    benchmark_version = `BM version introduced`
  )

parse_pdb <- function(x) {
  x <- as.character(x)
  pdb_id <- str_sub(x, 1, 4)
  chain_id <- str_replace(x, "^...._?", "")
  chain_id <- str_replace_all(chain_id, "\\(.*?\\)", "")
  chain_id <- ifelse(chain_id == "", NA, chain_id)
  data.frame(pdb_id = pdb_id, chain_id = chain_id)
}

p1 <- parse_pdb(bench$pdbid_1)
p2 <- parse_pdb(bench$pdbid_2)

bench$pdb1_clean <- p1$pdb_id
bench$chain1_clean <- p1$chain_id
bench$pdb2_clean <- p2$pdb_id
bench$chain2_clean <- p2$chain_id

structure_tbl <- bind_rows(
  bench %>%
    transmute(
      structure_id = paste0(str_sub(complex_id, 1, 4), "_bound"),
      pdb_id = str_sub(complex_id, 1, 4),
      structure_state = "bound",
      file_name = paste0(str_sub(complex_id, 1, 4), ".pdb")
    ),
  bench %>%
    transmute(
      structure_id = paste0(pdb1_clean, "_", chain1_clean, "_unbound"),
      pdb_id = pdb1_clean,
      structure_state = "unbound",
      file_name = paste0(pdb1_clean, "_", chain1_clean, ".pdb")
    ),
  bench %>%
    transmute(
      structure_id = paste0(pdb2_clean, "_", chain2_clean, "_unbound"),
      pdb_id = pdb2_clean,
      structure_state = "unbound",
      file_name = paste0(pdb2_clean, "_", chain2_clean, ".pdb")
    )
) %>%
  distinct()

protein_tbl <- bind_rows(
  bench %>%
    transmute(
      protein_name = protein_1,
      source_pdb_id = pdb1_clean,
      source_chain_id = chain1_clean
    ),
  bench %>%
    transmute(
      protein_name = protein_2,
      source_pdb_id = pdb2_clean,
      source_chain_id = chain2_clean
    )
) %>%
  distinct() %>%
  mutate(protein_id = row_number()) %>%
  select(protein_id, everything())

complex_tbl <- bench %>%
  transmute(
    complex_id,
    type_code,
    difficulty_level,
    bound_structure_id = paste0(str_sub(complex_id, 1, 4), "_bound")
  ) %>%
  distinct()

complex_protein_tbl <- bind_rows(
  bench %>%
    left_join(
      protein_tbl,
      by = c(
        "protein_1" = "protein_name",
        "pdb1_clean" = "source_pdb_id",
        "chain1_clean" = "source_chain_id"
      )
    ) %>%
    transmute(
      complex_id,
      protein_id,
      role = "Protein 1",
      unbound_structure_id = paste0(pdb1_clean, "_", chain1_clean, "_unbound"),
      unbound_chain_id = chain1_clean
    ),
  bench %>%
    left_join(
      protein_tbl,
      by = c(
        "protein_2" = "protein_name",
        "pdb2_clean" = "source_pdb_id",
        "chain2_clean" = "source_chain_id"
      )
    ) %>%
    transmute(
      complex_id,
      protein_id,
      role = "Protein 2",
      unbound_structure_id = paste0(pdb2_clean, "_", chain2_clean, "_unbound"),
      unbound_chain_id = chain2_clean
    )
) %>%
  distinct()

interaction_feature_tbl <- bench %>%
  transmute(
    complex_id,
    rmsd = as.numeric(rmsd),
    hetatms = NA_character_,
    interface_surface_area = as.numeric(interface_surface_area),
    benchmark_version = benchmark_version
  ) %>%
  distinct()

complex_type_tbl <- data.frame(
  type_code = c("EI", "ES", "ER", "AA", "AS", "OG", "OR", "OX"),
  type_description = c(
    "Enzyme-Inhibitor",
    "Enzyme-Substrate",
    "Enzyme with regulatory/accessory chain",
    "Antibody-Antigen",
    "Antigen-Single domain Antibody",
    "Others, G-protein containing",
    "Others, Receptor containing",
    "Others, miscellaneous"
  )
)

difficulty_tbl <- data.frame(
  difficulty_level = c("rigid", "medium", "difficult")
)

# -----------------------------
# Load
# -----------------------------
if (file.exists(db_path)) {
  file.remove(db_path)
}

con <- dbConnect(SQLite(), db_path)
dbExecute(con, "PRAGMA foreign_keys = ON;")

schema_sql <- paste(readLines(schema_path), collapse = "\n")
DBI::dbExecute(con, schema_sql)

dbWriteTable(con, "complex_type", complex_type_tbl, append = TRUE)
dbWriteTable(con, "difficulty", difficulty_tbl, append = TRUE)
dbWriteTable(con, "structure", structure_tbl, append = TRUE)
dbWriteTable(con, "protein", protein_tbl, append = TRUE)
dbWriteTable(con, "complex", complex_tbl, append = TRUE)
dbWriteTable(con, "complex_protein", complex_protein_tbl, append = TRUE)
dbWriteTable(con, "interaction_feature", interaction_feature_tbl, append = TRUE)

# -----------------------------
# Validation queries
# -----------------------------
cat("\nDatabase build complete.\n\n")

print(dbGetQuery(con, "SELECT COUNT(*) AS n_complexes FROM complex;"))
print(dbGetQuery(con, "SELECT COUNT(*) AS n_proteins FROM protein;"))
print(dbGetQuery(con, "SELECT COUNT(*) AS n_structures FROM structure;"))
print(dbGetQuery(con, "SELECT COUNT(*) AS n_interactions FROM interaction_feature;"))

cat("\nDocking difficulty counts:\n")
print(dbGetQuery(con, "
SELECT difficulty_level, COUNT(*) AS complex_count
FROM complex
GROUP BY difficulty_level;
"))

cat("\nComplex type counts:\n")
print(dbGetQuery(con, "
SELECT ct.type_description, COUNT(*) AS complex_count
FROM complex c
JOIN complex_type ct ON c.type_code = ct.type_code
GROUP BY ct.type_description
ORDER BY complex_count DESC;
"))

cat("\nProteins occurring in multiple complexes:\n")
print(dbGetQuery(con, "
SELECT 
    p.protein_name,
    p.source_pdb_id,
    p.source_chain_id,
    COUNT(cp.complex_id) AS complex_count
FROM protein p
JOIN complex_protein cp ON p.protein_id = cp.protein_id
GROUP BY p.protein_id, p.protein_name, p.source_pdb_id, p.source_chain_id
HAVING COUNT(cp.complex_id) > 1
ORDER BY complex_count DESC;
"))

dbDisconnect(con)
