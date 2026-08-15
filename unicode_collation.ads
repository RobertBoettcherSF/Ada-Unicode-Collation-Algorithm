--  unicode_collation.ads
--
--  Unicode Collation Algorithm (UCA) implementation
--  Based on Unicode Technical Report #10
--
--  This package implements the Unicode Collation Algorithm with support for:
--  - Multiple strength levels (Primary, Secondary, Tertiary, Quaternary)
--  - Variable weighting options (Non-Ignorable, Shifted, Shift-Trimmed)
--  - Parametric tailoring support
--  - Backward accents handling
--  - Normalization (simplified NFD for demonstration)
--

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Ada.Containers.Hashed_Maps;

package Unicode_Collation is

   -- ===================================================================
   --  TYPE DEFINITIONS
   -- ===================================================================

   -- Unicode code point type (0..0x10FFFF)
   type Unicode_Code_Point is range 0 .. 16#10FFFF#;
   type Code_Point_Array is array (Positive range <>) of Unicode_Code_Point;

   -- Collation strength levels
   type Strength_Level is (Primary, Secondary, Tertiary, Quaternary, Identical);
   type Strength_Level_Array is array (Strength_Level) of Boolean;

   -- Variable weighting options
   type Variable_Weighting is (Non_Ignorable, Shifted, Shift_Trimmed);

   -- Backward accents option
   type Backward_Accents is (Off, On);

   -- Case level option
   type Case_Level is (Off, On);

   -- Normalization mode
   type Normalization_Mode is (None, NFD);

   -- Collation element weight (16-bit unsigned)
   type Collation_Weight is range 0 .. 65535;
   type Weight_Array is array (Strength_Level range Primary .. Quaternary) of Collation_Weight;

   -- Collation element with weights for each level
   type Collation_Element is record
      Primary_Weight    : Collation_Weight := 0;
      Secondary_Weight  : Collation_Weight := 0;
      Tertiary_Weight    : Collation_Weight := 0;
      Quaternary_Weight : Collation_Weight := 0;
      Is_Variable        : Boolean := False;
   end record;

   -- Array of collation elements for a string
   type Collation_Element_Array is array (Positive range <>) of Collation_Element;

   -- Sort key: array of 16-bit weights with level separators
   type Sort_Key is array (Positive range <>) of Collation_Weight;

   -- String type for Unicode strings
   type Unicode_String is new String;

   -- ===================================================================
   --  PARAMETRIC SETTINGS (Tailoring options)
   -- ===================================================================

   -- Parametric settings record
   type Parametric_Settings is record
      Strength        : Strength_Level := Tertiary;
      Variable_Weight : Variable_Weighting := Non_Ignorable;
      Backward_Accents: Backward_Accents := Off;
      Case_Level       : Case_Level := Off;
      Normalization   : Normalization_Mode := NFD;
   end record;

   -- Default settings
   Default_Settings : constant Parametric_Settings :=
     (Strength        => Tertiary,
      Variable_Weight => Non_Ignorable,
      Backward_Accents=> Off,
      Case_Level       => Off,
      Normalization   => NFD);

   -- ===================================================================
   --  COLLATION ELEMENT TABLE
   -- ===================================================================

   -- Simplified Collation Element Table type
   -- Maps code points to collation elements
   -- In a full implementation, this would be the DUCET with expansions, contractions, etc.
   type CET_Entry is record
      Element : Collation_Element;
   end record;

   -- Collation Element Table (simplified for demonstration)
   -- Uses a map from code point to collation element
   package CET_Maps is new Ada.Containers.Hashed_Maps(
      Key_Type        => Unicode_Code_Point,
      Element_Type    => CET_Entry,
      Hash            => Unicode_Code_Point_Hash,
      Equivalent_Keys => Unicode_Code_Point_Equal);

   use CET_Maps;

   -- The default collation element table (DUCET subset)
   DUCET : CET_Maps.Map;

   -- ===================================================================
   --  EXCEPTIONS
   -- ===================================================================

   Collation_Error : exception;
   Normalization_Error : exception;
   Invalid_Code_Point : exception;
   Table_Not_Initialized : exception;

   -- ===================================================================
   --  MAIN ALGORITHM PROCEDURES
   -- ===================================================================

   -- Step 1: Normalize string (NFD)
   -- In full implementation, this would decompose characters
   function Normalize (
      Input  : Unicode_String;
      Mode   : Normalization_Mode := NFD)
     return Unicode_String;

   -- Step 2: Produce collation element array from string
   function Produce_Collation_Elements (
      Input    : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Collation_Element_Array;

   -- Step 3: Form sort key from collation element array
   function Form_Sort_Key (
      Elements : Collation_Element_Array;
      Settings : Parametric_Settings := Default_Settings)
     return Sort_Key;

   -- Step 4: Compare two sort keys
   function Compare_Sort_Keys (
      Key1     : Sort_Key;
      Key2     : Sort_Key;
      Settings : Parametric_Settings := Default_Settings)
     return Integer;
      -- Returns: -1 if Key1 < Key2, 0 if equal, +1 if Key1 > Key2

   -- ===================================================================
   --  HIGH-LEVEL COLLATION FUNCTIONS
   -- ===================================================================

   -- Full UCA comparison of two strings
   function Compare (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Integer;
      -- Returns: -1 if Str1 < Str2, 0 if equal, +1 if Str1 > Str2

   -- Sort an array of strings
   procedure Sort (
      Strings  : in out Ada.Containers.Vectors.Vector;
      Settings : Parametric_Settings := Default_Settings);

   -- Check if two strings are equal according to collation rules
   function Are_Equal (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Boolean;

   -- ===================================================================
   --  VARIANT-SPECIFIC PROCEDURES
   -- ===================================================================

   -- Preemptive variant: Compare with early termination
   function Compare_Preemptive (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Integer;

   -- Non-preemptive variant: Full comparison
   function Compare_Non_Preemptive (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Integer;

   -- Static tailoring: Use pre-defined tailoring
   function Compare_Static_Tailored (
      Str1      : Unicode_String;
      Str2      : Unicode_String;
      Tailoring : CET_Maps.Map;
      Settings  : Parametric_Settings := Default_Settings)
     return Integer;

   -- Dynamic tailoring: Modify settings at runtime
   function Compare_Dynamic_Tailored (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings)
     return Integer;

   -- ===================================================================
   --  STRENGTH LEVEL VARIANTS
   -- ===================================================================

   -- Compare at Primary level only
   function Compare_Primary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer;

   -- Compare at Secondary level (Primary + Secondary)
   function Compare_Secondary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer;

   -- Compare at Tertiary level (Primary + Secondary + Tertiary)
   function Compare_Tertiary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer;

   -- Compare at Quaternary level (all levels)
   function Compare_Quaternary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer;

   -- ===================================================================
   --  VARIABLE WEIGHTING VARIANTS
   -- ===================================================================

   -- Compare with Non-Ignorable variable weighting
   function Compare_Non_Ignorable (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer;

   -- Compare with Shifted variable weighting
   function Compare_Shifted (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer;

   -- Compare with Shift-Trimmed variable weighting
   function Compare_Shift_Trimmed (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer;

   -- ===================================================================
   --  HELPER FUNCTIONS
   -- ===================================================================

   -- Hash function for Unicode code points
   function Unicode_Code_Point_Hash (Key : Unicode_Code_Point) return Ada.Containers.Hash_Type;

   -- Equality for Unicode code points
   function Unicode_Code_Point_Equal (Left, Right : Unicode_Code_Point) return Boolean;

   -- Convert string to code point array
   function To_Code_Points (S : Unicode_String) return Code_Point_Array;

   -- Convert code point array to string
   function To_Unicode_String (Points : Code_Point_Array) return Unicode_String;

   -- Get collation element for a code point
   function Get_Collation_Element (
      Code_Point : Unicode_Code_Point;
      Table      : CET_Maps.Map := DUCET)
     return Collation_Element;

   -- Initialize the DUCET with default values
   procedure Initialize_DUCET;

   -- Check if DUCET is initialized
   function Is_DUCET_Initialized return Boolean;

   -- Get the current level separator value
   function Get_Level_Separator return Collation_Weight;

   -- ===================================================================
   --  VALIDATION FUNCTIONS
   -- ===================================================================

   -- Validate a Unicode string
   function Is_Valid_Unicode_String (S : Unicode_String) return Boolean;

   -- Validate a code point
   function Is_Valid_Code_Point (CP : Unicode_Code_Point) return Boolean;

   -- Validate parametric settings
   function Are_Valid_Settings (Settings : Parametric_Settings) return Boolean;

end Unicode_Collation;
