#!/usr/bin/env Rscript

# Script to add protein sequences from PDB files to the database
# Adjusted for your schema with source_pdb_id column

library(bio3d)
library(RSQLite)
library(DBI)

# Connect to your database
conn <- dbConnect(SQLite(), "ppi_benchmark_FULL.db")

# Check if sequence column exists (it should now)
columns <- dbListFields(conn, "protein")
if (!"sequence" %in% columns) {
  cat("ERROR: sequence column not found! Run the ALTER TABLE command first.\n")
  quit(status=1)
}

# Get unique PDB IDs from your database (using source_pdb_id)
pdb_ids <- dbGetQuery(conn, "SELECT DISTINCT source_pdb_id FROM protein WHERE source_pdb_id IS NOT NULL AND source_pdb_id != ''")
cat(sprintf("Found %d unique PDB IDs to process\n", nrow(pdb_ids)))

# Create a progress counter
success_count <- 0
fail_count <- 0

# Fetch and store sequences
for(i in 1:nrow(pdb_ids)) {
  pdb_id <- pdb_ids$source_pdb_id[i]
  cat(sprintf("[%d/%d] Processing %s... ", i, nrow(pdb_ids), pdb_id))
  
  # Try to download and read PDB file
  pdb <- tryCatch({
    read.pdb(pdb_id)
  }, error = function(e) {
    return(NULL)
  })
  
  if(!is.null(pdb) && !is.null(pdb$seq) && length(pdb$seq) > 0) {
    # Get the sequence as a single string
    seq <- paste(pdb$seq, collapse="")
    
    # Update the database (using source_pdb_id)
    result <- dbExecute(conn, 
              "UPDATE protein SET sequence = ? WHERE source_pdb_id = ?",
              params = list(seq, pdb_id))
    
    cat(sprintf("✓ Added sequence (%d residues) for %d protein(s)\n", nchar(seq), result))
    success_count <- success_count + 1
  } else {
    cat("✗ Failed to get sequence\n")
    fail_count <- fail_count + 1
  }
  
  # Be nice to PDB servers - add a small delay
  Sys.sleep(0.5)
}

cat("\n========== SUMMARY ==========\n")
cat(sprintf("Successfully added sequences: %d\n", success_count))
cat(sprintf("Failed: %d\n", fail_count))
cat("=============================\n")

# Verify some sequences were added
sample_sequences <- dbGetQuery(conn, 
  "SELECT source_pdb_id, protein_name, substr(sequence, 1, 50) as seq_preview, length(sequence) as seq_length
   FROM protein 
   WHERE sequence IS NOT NULL 
   LIMIT 5")

cat("\nSample sequences added:\n")
print(sample_sequences)

# Count how many proteins now have sequences
seq_count <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM protein WHERE sequence IS NOT NULL")
total_count <- dbGetQuery(conn, "SELECT COUNT(*) as count FROM protein")
cat(sprintf("\nSequences added to %d out of %d proteins (%.1f%%)\n", 
    seq_count$count, total_count$count, 100*seq_count$count/total_count$count))

# Close connection
dbDisconnect(conn)

cat("\nDone! Sequences have been added to database.\n")
