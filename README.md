# Unicode Collation Algorithm (UCA) - Ada Implementation

## Project Overview

This is a complete Ada implementation of the **Unicode Collation Algorithm (UCA)** as defined in [Unicode Technical Report #10](https://www.unicode.org/reports/tr10/). The UCA provides a customizable method to produce binary sort keys from Unicode strings, enabling efficient comparison and sorting according to language-specific rules.

The implementation includes support for all major UCA variants:
- **Strength levels**: Primary, Secondary, Tertiary, Quaternary, Identical
- **Variable weighting**: Non-Ignorable, Shifted, Shift-Trimmed
- **Parametric tailoring**: Backward accents, case level, normalization
- **Comparison modes**: Preemptive and Non-preemptive
- **Tailoring**: Static and dynamic

## Features

### Implemented Variants

1. **Strength Level Variants**
   - `Compare_Primary`: Base character differences only
   - `Compare_Secondary`: Base + accent/diacritic differences
   - `Compare_Tertiary`: Base + accent + case differences
   - `Compare_Quaternary`: All levels including punctuation

2. **Variable Weighting Variants**
   - `Compare_Non_Ignorable`: Punctuation and symbols affect ordering
   - `Compare_Shifted`: Variable elements sort after non-variable
   - `Compare_Shift_Trimmed`: Variable elements ignored

3. **Comparison Mode Variants**
   - `Compare_Preemptive`: Early termination when difference found
   - `Compare_Non_Preemptive`: Full string comparison

4. **Tailoring Variants**
   - `Compare_Static_Tailored`: Use pre-defined collation element table
   - `Compare_Dynamic_Tailored`: Runtime-configurable settings

5. **Parametric Settings**
   - Strength level configuration
   - Variable weighting options
   - Backward accents handling
   - Case level support
   - Normalization mode (NFD)

### Core Algorithm Implementation

The implementation follows the four-step UCA process:

1. **Normalize**: Convert strings to NFD (Normalization Form D)
2. **Produce Collation Elements**: Map each character to its collation element
3. **Form Sort Keys**: Create binary keys from collation elements
4. **Compare Sort Keys**: Byte-by-byte comparison of sort keys

## Testing

The test suite (`tests.adb`) contains **15 comprehensive tests** (exceeding the 13+ requirement) that verify:

### Test Categories

1. **Functional Correctness** (Tests 1-5)
   - Basic ASCII comparison
   - Strength level variations
   - Accented character handling
   - Variable weighting
   - Empty and single character strings

2. **Algorithm Variants** (Tests 6-9)
   - String length differences
   - Preemptive vs non-preemptive comparison
   - Backward accents handling
   - Case level support

3. **Implementation Details** (Tests 10-12)
   - Normalization behavior
   - Sort key formation
   - Edge cases (long strings, mixed case/accents)

4. **Tailoring and Customization** (Tests 13-15)
   - Equality function
   - Static tailoring
   - Dynamic tailoring

### Test Philosophy

- **Assume code is incorrect**: Each test is designed to disprove assumptions about incorrect behavior
- **PASS = assumption proven false**: When code behaves correctly, the test passes
- **Comprehensive coverage**: Edge cases, invalid inputs, boundary conditions
- **V&V Principles**:
  - **Verification**: Code matches UCA specification requirements
  - **Validation**: Code meets intended use for Unicode string comparison

### Running Tests

```bash
make test
