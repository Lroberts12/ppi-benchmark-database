Protein–Protein Interaction Database Design and Query System

This project implements a fully normalized relational database for storing, querying, and analyzing protein–protein interaction benchmark data from the Protein–Protein Docking Benchmark v5.5. The database was developed using SQLite, R, and relational database design principles to model experimentally validated protein interaction complexes and associated structural features derived from Protein Data Bank (PDB) records.

The project demonstrates:

* Relational schema design
* Database normalization (3NF)
* ETL (Extract, Transform, Load) workflows
* SQL querying
* Biological data integration
* Data visualization and reporting in R

⸻

Features

* Imports the full Docking Benchmark v5.5 dataset into SQLite
* Implements a fully normalized relational schema
* Preserves referential integrity using primary and foreign keys
* Stores:
    * Protein metadata
    * Bound and unbound structures
    * Interaction categories
    * Docking difficulty levels
    * RMSD and interface surface area measurements
* Demonstrates many-to-many biological relationships using junction tables
* Generates professional figures and summary tables in R
* Supports complex biological SQL queries and aggregation analyses

⸻

Technologies Used

* SQLite
* R
* DBI
* RSQLite
* dplyr
* tidyr
* stringr
* ggplot2
* readxl
* gridExtra
* DiagrammeR

⸻

Database Design

The schema was normalized to Third Normal Form (3NF) to reduce redundancy and maintain data integrity.

Core Tables
# Core Tables

| Table | Description |
|---|---|
| complex | Stores benchmark protein–protein complexes |
| protein | Stores unique proteins and associated PDB metadata |
| structure | Stores bound and unbound structural records |
| complex_protein | Junction table linking proteins to complexes |
| interaction_feature | Stores RMSD and interface surface area measurements |
| complex_type | Lookup table for interaction categories |
| difficulty | Lookup table for docking difficulty levels |

Normalization

The schema satisfies Third Normal Form (3NF):

First Normal Form (1NF)

* All attributes are atomic
* No repeating groups

Second Normal Form (2NF)

* No partial dependencies on composite keys

Third Normal Form (3NF)

* No transitive dependencies between non-key attributes

⸻

ETL Workflow

Extract

Data was extracted from the Protein–Protein Docking Benchmark v5.5 Excel dataset, including:

* Complex identifiers
* PDB IDs
* Protein names
* Chain identifiers
* RMSD values
* Interface surface area values
* Interaction classifications

Transform

The dataset was cleaned and standardized:

* PDB IDs and chain IDs were parsed
* Controlled vocabularies were implemented
* Bound/unbound structures were separated
* Interaction metrics were standardized
* Duplicate records were removed

Load

The transformed data was loaded into SQLite tables in dependency order:

1. Lookup tables
2. Structures
3. Proteins
4. Complexes
5. Junction tables
6. Interaction features

Foreign key constraints were enforced throughout loading to preserve referential integrity.

⸻

Project Structure
ppi-benchmark-database/
│
├── README.md
│
├── data/
│   └── Table_BM5.5.xlsx
│
├── database/
│   ├── ppi_benchmark_FULL.db
│   └── schema.sql
│
├── scripts/
│   └── build_ppi_database.R
│
├── figures/
│   ├── ppi_clean_er_diagram.png
│   ├── docking_difficulty_barplot.png
│   ├── table1_database_summary.png
│   ├── table2_difficulty_distribution.png
│   ├── table3_complex_type_distribution.png
│   ├── table4_multiple_complex_proteins.png
│   └── table5_interaction_features.png
│
└── outputs/
    └── example_query_outputs.txt

Example Database Statistics

# Example Database Statistics

| Entity | Records |
|---|---|
| Complexes | 257 |
| Proteins | 489 |
| Structures | 733 |
| Interaction Features | 257 |

SQL Queries Used

Complex Type and Docking Difficulty

SELECT c.complex_id, ct.type_description, c.difficulty_level
FROM complex c
JOIN complex_type ct
ON c.type_code = ct.type_code;

Proteins Participating in Multiple Complexes

SELECT 
    p.protein_name,
    COUNT(cp.complex_id) AS complex_count
FROM protein p
JOIN complex_protein cp
ON p.protein_id = cp.protein_id
GROUP BY p.protein_name
HAVING COUNT(cp.complex_id) > 1;

Interaction Features

SELECT *
FROM interaction_feature;

Figures and Visualizations

The project includes:

* ER diagrams
* Summary tables
* Docking difficulty distributions
* Complex type distributions
* Protein participation summaries
* Interaction feature tables

All figures were generated in R.

How to Run

Clone Repository
git clone https://github.com/Lroberts12/ppi-benchmark-database.git
cd ppi-benchmark-database

Open db
sqlite3 database/ppi_benchmark_FULL.db

Run ETL Script in R
source("scripts/build_ppi_database.R")

Biological Significance

This database models experimentally validated protein–protein interactions and supports:

* Structural biology analysis
* Docking benchmark studies
* Interaction classification
* Protein reuse across complexes
* Query-based biological exploration

The normalized schema supports scalable integration of future benchmark datasets and additional structural annotations.

Author

Lindsay Roberts
Master’s Student — Bioinformatics
UNC Charlotte

⸻

Acknowledgments

This project used:

* Protein–Protein Docking Benchmark v5.5
* Protein Data Bank (PDB)
* SQLiteStudio
* R and associated data science libraries
* OpenAI ChatGPT for assistance with:
    * Documentation formatting
    * SQL debugging
    * ETL workflow troubleshooting
