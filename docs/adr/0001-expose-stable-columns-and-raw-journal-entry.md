# Expose stable columns and the raw Journal Entry

The `journal` relation exposes a small set of stable, lower-case columns for common analysis and also exposes the complete Journal Entry in an `entry` JSON column. Fully inferred columns would make SQL types unstable when journal fields are missing, repeated, binary, or application-defined, while a JSON-only relation would make common queries unnecessarily difficult. Stable columns use non-throwing conversion and contain `NULL` when the source value is missing or cannot be converted; `entry` preserves the original value.
