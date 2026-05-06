PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS interaction_feature;
DROP TABLE IF EXISTS complex_protein;
DROP TABLE IF EXISTS complex;
DROP TABLE IF EXISTS protein;
DROP TABLE IF EXISTS structure;
DROP TABLE IF EXISTS difficulty;
DROP TABLE IF EXISTS complex_type;

CREATE TABLE complex_type (
    type_code TEXT PRIMARY KEY,
    type_description TEXT NOT NULL
);

CREATE TABLE difficulty (
    difficulty_level TEXT PRIMARY KEY
);

CREATE TABLE structure (
    structure_id TEXT PRIMARY KEY,
    pdb_id TEXT NOT NULL,
    structure_state TEXT CHECK (structure_state IN ('bound','unbound')),
    file_name TEXT
);

CREATE TABLE protein (
    protein_id INTEGER PRIMARY KEY,
    protein_name TEXT,
    source_pdb_id TEXT,
    source_chain_id TEXT
);

CREATE TABLE complex (
    complex_id TEXT PRIMARY KEY,
    type_code TEXT,
    difficulty_level TEXT,
    bound_structure_id TEXT,
    FOREIGN KEY (type_code) REFERENCES complex_type(type_code),
    FOREIGN KEY (difficulty_level) REFERENCES difficulty(difficulty_level),
    FOREIGN KEY (bound_structure_id) REFERENCES structure(structure_id)
);

CREATE TABLE complex_protein (
    complex_id TEXT,
    protein_id INTEGER,
    role TEXT,
    unbound_structure_id TEXT,
    unbound_chain_id TEXT,
    PRIMARY KEY (complex_id, protein_id),
    FOREIGN KEY (complex_id) REFERENCES complex(complex_id),
    FOREIGN KEY (protein_id) REFERENCES protein(protein_id)
);

CREATE TABLE interaction_feature (
    complex_id TEXT PRIMARY KEY,
    rmsd REAL,
    hetatms TEXT,
    interface_surface_area REAL,
    benchmark_version REAL,
    FOREIGN KEY (complex_id) REFERENCES complex(complex_id)
);
