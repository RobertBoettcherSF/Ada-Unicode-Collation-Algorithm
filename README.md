# Unicode Collation Algorithm (UCA) - Ada Implementation

## Project Overview

Complete Ada implementation of the **Unicode Collation Algorithm (UCA)** as defined in Unicode Technical Report #10. Provides customizable string comparison and sorting according to language-specific rules.

## Features

### Implemented Variants
- **Strength Levels**: Primary, Secondary, Tertiary, Quaternary, Identical
- **Variable Weighting**: Non-Ignorable, Shifted, Shift-Trimmed  
- **Comparison Modes**: Preemptive and Non-preemptive
- **Tailoring**: Static and dynamic
- **Parametric Settings**: Backward accents, case level, normalization

## Testing

**15 tests with 45+ assertions** verifying:
- Functional correctness (basic comparisons, strength levels)
- Algorithm variants (preemptive/non-preemptive, tailoring)
- Edge cases (empty strings, long strings, special characters)
- V&V: Verification (code matches spec), Validation (code meets intended use)

### Run Tests
```bash
make test
