with Ada.Strings.Unbounded;
with Ada.Containers.Hashed_Maps;

package Unicode_Collation is

   type Unicode_Code_Point is range 0 .. 16#10FFFF#;

   type Strength_Level is (Primary, Secondary, Tertiary, Quaternary, Identical);
   type Variable_Weighting is (Non_Ignorable, Shifted, Shift_Trimmed);
   type Backward_Accents is (Off, On);
   type Case_Level is (Off, On);
   type Normalization_Mode is (None, NFD);

   type Collation_Weight is range 0 .. 65535;

   type Collation_Element is record
      Primary_Weight    : Collation_Weight := 0;
      Secondary_Weight  : Collation_Weight := 0;
      Tertiary_Weight    : Collation_Weight := 0;
      Quaternary_Weight : Collation_Weight := 0;
      Is_Variable        : Boolean := False;
   end record;

   type Code_Point_Array is array (Positive range <>) of Unicode_Code_Point;
   type Collation_Element_Array is array (Positive range <>) of Collation_Element;
   type Sort_Key is array (Positive range <>) of Collation_Weight;

   function Unicode_Code_Point_Hash (Key : Unicode_Code_Point) return Ada.Containers.Hash_Type;
   function Unicode_Code_Point_Equal (Left, Right : Unicode_Code_Point) return Boolean;

   type CET_Entry is record
      Element : Collation_Element;
   end record;

   package CET_Maps is new Ada.Containers.Hashed_Maps(
      Key_Type        => Unicode_Code_Point,
      Element_Type    => CET_Entry,
      Hash            => Unicode_Code_Point_Hash,
      Equivalent_Keys => Unicode_Code_Point_Equal);

   use CET_Maps;

   DUCET : CET_Maps.Map;

   type Parametric_Settings is record
      Strength        : Strength_Level;
      Variable_Weight : Variable_Weighting;
      Backward_Accents: Backward_Accents;
      Case_Level       : Case_Level;
      Normalization   : Normalization_Mode;
   end record;

   Default_Settings : constant Parametric_Settings := 
     (Tertiary, Non_Ignorable, Off, Off, NFD);

   Collation_Error : exception;
   Normalization_Error : exception;
   Invalid_Code_Point : exception;

   function Normalize (Input : String; Mode : Normalization_Mode := NFD) return String;
   function Produce_Collation_Elements (Input : String; Settings : Parametric_Settings := Default_Settings) return Collation_Element_Array;
   function Form_Sort_Key (Elements : Collation_Element_Array; Settings : Parametric_Settings := Default_Settings) return Sort_Key;
   function Compare_Sort_Keys (Key1, Key2 : Sort_Key; Settings : Parametric_Settings := Default_Settings) return Integer;

   function Compare (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Integer;
   function Are_Equal (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Boolean;

   function Compare_Preemptive (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Integer;
   function Compare_Non_Preemptive (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Integer;
   function Compare_Static_Tailored (Str1, Str2 : String; Tailoring : CET_Maps.Map; Settings : Parametric_Settings := Default_Settings) return Integer;
   function Compare_Dynamic_Tailored (Str1, Str2 : String; Settings : Parametric_Settings) return Integer;

   function Compare_Primary (Str1, Str2 : String) return Integer;
   function Compare_Secondary (Str1, Str2 : String) return Integer;
   function Compare_Tertiary (Str1, Str2 : String) return Integer;
   function Compare_Quaternary (Str1, Str2 : String) return Integer;

   function Compare_Non_Ignorable (Str1, Str2 : String) return Integer;
   function Compare_Shifted (Str1, Str2 : String) return Integer;
   function Compare_Shift_Trimmed (Str1, Str2 : String) return Integer;

   function To_Code_Points (S : String) return Code_Point_Array;
   function Get_Collation_Element (Code_Point : Unicode_Code_Point; Table : CET_Maps.Map := DUCET) return Collation_Element;

   procedure Initialize_DUCET;
   function Is_DUCET_Initialized return Boolean;
   function Get_Level_Separator return Collation_Weight;

   function Is_Valid_Code_Point (CP : Unicode_Code_Point) return Boolean;
   function Are_Valid_Settings (Settings : Parametric_Settings) return Boolean;

end Unicode_Collation;
