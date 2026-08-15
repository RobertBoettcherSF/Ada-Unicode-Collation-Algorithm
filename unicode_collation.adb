--  unicode_collation.adb
--
--  Implementation of the Unicode Collation Algorithm
--  Based on Unicode Technical Report #10
--

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Ada.Containers.Hashed_Maps;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Strings.UTF_Encoding; use Ada.Strings.UTF_Encoding;
with Ada.Strings.UTF_Encoding.Conversions; use Ada.Strings.UTF_Encoding.Conversions;

package body Unicode_Collation is

   -- Level separator value (0x0000 as per UCA)
   Level_Separator : constant Collation_Weight := 0;

   -- DUCET initialization flag
   DUCET_Initialized : Boolean := False;

   -- Maximum weight value
   Max_Weight : constant Collation_Weight := 65535;

   -- ===================================================================
   --  HASH AND EQUALITY FOR CODE POINTS
   -- ===================================================================

   function Unicode_Code_Point_Hash (Key : Unicode_Code_Point) return Ada.Containers.Hash_Type is
   begin
      return Ada.Containers.Hash_Type(Key mod 2**32);
   end Unicode_Code_Point_Hash;

   function Unicode_Code_Point_Equal (Left, Right : Unicode_Code_Point) return Boolean is
   begin
      return Left = Right;
   end Unicode_Code_Point_Equal;

   -- ===================================================================
   --  DUCET INITIALIZATION
   -- ===================================================================

   procedure Initialize_DUCET is
   begin
      if DUCET_Initialized then
         return;
      end if;

      -- Clear existing entries
      DUCET.Clear;

      -- =================================================================
      --  SIMPLIFIED DUCET FOR DEMONSTRATION
      --  In a full implementation, this would contain all Unicode characters
      --  with their proper collation weights from the actual DUCET.
      --
      --  Weights are assigned as follows:
      --  - Primary: Base character order
      --  - Secondary: Diacritic/accent differences
      --  - Tertiary: Case differences
      --  - Quaternary: Other differences
      --
      --  This simplified version covers:
      --  - Basic Latin letters (A-Z, a-z)
      --  - Common accented characters (é, è, ê, etc.)
      --  - Some punctuation and symbols
      -- =================================================================

      -- Level separators (0x0000)
      -- Not stored in table, handled separately

      -- Basic Latin letters - Primary weights
      -- A-Z: 0x2000-0x2019 (32 values)
      -- a-z: 0x201A-0x2033 (26 values, same primary as uppercase for case-insensitive)
      -- But we want case differences at tertiary level

      -- Define base weights
      -- Primary weights for letters (A=0x2000, B=0x2001, ..., Z=0x2019)
      -- a-z have same primary but different tertiary

      -- Helper to add entry
      procedure Add_Entry (
         CP : Unicode_Code_Point;
         P, S, T, Q : Collation_Weight;
         Variable : Boolean := False) is
      begin
         DUCET.Insert(
            Key => CP,
            New_Item => CET_Entry'(
               Element => Collation_Element'(
                  Primary_Weight => P,
                  Secondary_Weight => S,
                  Tertiary_Weight => T,
                  Quaternary_Weight => Q,
                  Is_Variable => Variable)));
      end Add_Entry;

      -- Space and punctuation (variable elements)
      Add_Entry(32, 0x0001, 0, 0, 0, True);   -- Space
      Add_Entry(33, 0x0002, 0, 0, 0, True);   -- !
      Add_Entry(34, 0x0003, 0, 0, 0, True);   -- "
      Add_Entry(39, 0x0004, 0, 0, 0, True);   -- '
      Add_Entry(44, 0x0005, 0, 0, 0, True);   -- ,
      Add_Entry(45, 0x0006, 0, 0, 0, True);   -- -
      Add_Entry(46, 0x0007, 0, 0, 0, True);   -- .
      Add_Entry(58, 0x0008, 0, 0, 0, True);   -- :
      Add_Entry(59, 0x0009, 0, 0, 0, True);   -- ;

      -- Digits (0-9) - variable, same primary weight for numeric ordering
      Add_Entry(48, 0x0010, 0, 0, 0, True);   -- 0
      Add_Entry(49, 0x0011, 0, 0, 0, True);   -- 1
      Add_Entry(50, 0x0012, 0, 0, 0, True);   -- 2
      Add_Entry(51, 0x0013, 0, 0, 0, True);   -- 3
      Add_Entry(52, 0x0014, 0, 0, 0, True);   -- 4
      Add_Entry(53, 0x0015, 0, 0, 0, True);   -- 5
      Add_Entry(54, 0x0016, 0, 0, 0, True);   -- 6
      Add_Entry(55, 0x0017, 0, 0, 0, True);   -- 7
      Add_Entry(56, 0x0018, 0, 0, 0, True);   -- 8
      Add_Entry(57, 0x0019, 0, 0, 0, True);   -- 9

      -- Uppercase letters A-Z
      -- Primary weights: 0x2000 to 0x2019
      for I in 0 .. 25 loop
         Add_Entry(
            CP => Unicode_Code_Point(65 + I),  -- A to Z
            P => 0x2000 + Collation_Weight(I),
            S => 0,
            T => 2,  -- Uppercase has lower tertiary weight
            Q => 0);
      end loop;

      -- Lowercase letters a-z
      -- Same primary as uppercase, different tertiary
      for I in 0 .. 25 loop
         Add_Entry(
            CP => Unicode_Code_Point(97 + I),  -- a to z
            P => 0x2000 + Collation_Weight(I),
            S => 0,
            T => 3,  -- Lowercase has higher tertiary weight
            Q => 0);
      end loop;

      -- Accented characters (Latin-1 Supplement)
      -- é (e with acute) - U+00E9
      Add_Entry(233, 0x2004, 0x0020, 0, 0);  -- é: same primary as e, secondary difference
      -- è (e with grave) - U+00E8
      Add_Entry(232, 0x2004, 0x0021, 0, 0);  -- è: same primary as e, different secondary
      -- ê (e with circumflex) - U+00EA
      Add_Entry(234, 0x2004, 0x0022, 0, 0);  -- ê
      -- ã (a with tilde) - U+00E3
      Add_Entry(227, 0x2000, 0x0020, 0, 0);  -- ã
      -- á (a with acute) - U+00E1
      Add_Entry(225, 0x2000, 0x0021, 0, 0);  -- á
      -- à (a with grave) - U+00E0
      Add_Entry(224, 0x2000, 0x0022, 0, 0);  -- à

      -- Additional characters
      Add_Entry(196, 0x2000, 0x0023, 2, 0);  -- Ä
      Add_Entry(228, 0x2000, 0x0023, 3, 0);  -- ä
      Add_Entry(214, 0x2014, 0x0020, 2, 0);  -- Ö
      Add_Entry(246, 0x2014, 0x0020, 3, 0);  -- ö
      Add_Entry(220, 0x2018, 0x0020, 2, 0);  -- Ü
      Add_Entry(252, 0x2018, 0x0020, 3, 0);  -- ü

      -- Special: ß (sharp s) - U+00DF
      Add_Entry(223, 0x2019, 0, 0, 0);  -- ß sorts after z

      DUCET_Initialized := True;
   exception
      when others =>
         DUCET_Initialized := False;
         raise;
   end Initialize_DUCET;

   function Is_DUCET_Initialized return Boolean is
   begin
      return DUCET_Initialized;
   end Is_DUCET_Initialized;

   -- ===================================================================
   --  NORMALIZATION (Simplified NFD)
   -- ===================================================================

   -- Simplified NFD normalization
   -- In a full implementation, this would use proper Unicode normalization
   -- For demonstration, we handle a few common precomposed characters
   function Normalize (
      Input  : Unicode_String;
      Mode   : Normalization_Mode := NFD)
     return Unicode_String is
   begin
      if Mode = None then
         return Input;
      end if;

      -- Simplified NFD: Decompose some precomposed characters
      -- This is a very limited implementation for demonstration
      declare
         Result : Unicode_String := Input;
         Output : Unbounded_String;
      begin
         for I in 1 .. Result'Length loop
            case Result(I) is
               when Character'Val(196) => -- Ä -> A + ˘
                  Append(Output, "A");
                  -- In real NFD: would add combining diaeresis (U+0308)
               when Character'Val(228) => -- ä -> a + ˘
                  Append(Output, "a");
               when Character'Val(214) => -- Ö -> O + ˘
                  Append(Output, "O");
               when Character'Val(246) => -- ö -> o + ˘
                  Append(Output, "o");
               when Character'Val(220) => -- Ü -> U + ˘
                  Append(Output, "U");
               when Character'Val(252) => -- ü -> u + ˘
                  Append(Output, "u");
               when others =>
                  Append(Output, Result(I));
            end case;
         end loop;
         return Unicode_String(To_String(Output));
      end;
   exception
      when others =>
         raise Normalization_Error with "Normalization failed";
   end Normalize;

   -- ===================================================================
   --  CODE POINT CONVERSION
   -- ===================================================================

   function To_Code_Points (S : Unicode_String) return Code_Point_Array is
      Result : Code_Point_Array(1 .. S'Length);
   begin
      for I in S'Range loop
         -- Convert Wide_Character to Unicode_Code_Point
         -- For ASCII, this is straightforward
         Result(I) := Unicode_Code_Point(Character'Pos(S(I)));
      end loop;
      return Result;
   exception
      when others =>
         raise Invalid_Code_Point with "Invalid code point in string";
   end To_Code_Points;

   function To_Unicode_String (Points : Code_Point_Array) return Unicode_String is
      Result : Unicode_String(1 .. Points'Length);
   begin
      for I in Points'Range loop
         if Points(I) <= 255 then
            Result(I) := Character'Val(Points(I));
         else
            -- For non-ASCII, we'll use a placeholder
            Result(I) := '?';
         end if;
      end loop;
      return Result;
   exception
      when others =>
         raise Invalid_Code_Point with "Invalid code point conversion";
   end To_Unicode_String;

   -- ===================================================================
   --  COLLATION ELEMENT LOOKUP
   -- ===================================================================

   function Get_Collation_Element (
      Code_Point : Unicode_Code_Point;
      Table      : CET_Maps.Map := DUCET)
     return Collation_Element is
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;

      if Table.Contains(Key => Code_Point) then
         return Table.Element(Key => Code_Point).Element;
      else
         -- Default collation element for unknown characters
         -- Use code point value as primary weight, others 0
         return Collation_Element'(
            Primary_Weight => Collation_Weight(Code_Point mod 65536),
            Secondary_Weight => 0,
            Tertiary_Weight => 0,
            Quaternary_Weight => 0,
            Is_Variable => True);
      end if;
   end Get_Collation_Element;

   -- ===================================================================
   --  STEP 2: PRODUCE COLLATION ELEMENT ARRAY
   -- ===================================================================

   function Produce_Collation_Elements (
      Input    : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Collation_Element_Array is
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;

      -- Step 2.1: Normalize the input string
      declare
         Normalized : Unicode_String := Normalize(Input, Settings.Normalization);
         Points     : Code_Point_Array := To_Code_Points(Normalized);
         Result     : Collation_Element_Array(1 .. Points'Length);
      begin
         -- Step 2.2: For each code point, get its collation element
         for I in Points'Range loop
            Result(I) := Get_Collation_Element(Points(I), DUCET);
         end loop;

         return Result;
      end;
   exception
      when others =>
         raise Collation_Error with "Failed to produce collation elements";
   end Produce_Collation_Elements;

   -- ===================================================================
   --  STEP 3: FORM SORT KEY
   -- ===================================================================

   function Form_Sort_Key (
      Elements : Collation_Element_Array;
      Settings : Parametric_Settings := Default_Settings)
     return Sort_Key is

      -- Calculate maximum sort key length
      -- Each collation element contributes up to 4 weights + level separators
      Max_Length : constant Positive := Elements'Length * 5;

      -- Build sort key
      Result_Index : Positive := 1;
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;

      -- Allocate maximum possible size
      declare
         Result : Sort_Key(1 .. Max_Length);
      begin
         for Element of Elements loop
            -- Add primary weight if strength >= Primary
            if Settings.Strength >= Primary then
               Result(Result_Index) := Element.Primary_Weight;
               Result_Index := Result_Index + 1;

               -- Add level separator if more levels follow
               if Settings.Strength >= Secondary then
                  Result(Result_Index) := Level_Separator;
                  Result_Index := Result_Index + 1;
               end if;
            end if;

            -- Add secondary weight if strength >= Secondary
            if Settings.Strength >= Secondary then
               -- Handle backward accents
               declare
                  Secondary_Weight : Collation_Weight := Element.Secondary_Weight;
               begin
                  if Settings.Backward_Accents = On then
                     -- Invert secondary weights for backward accents
                     Secondary_Weight := Max_Weight - Secondary_Weight;
                  end if;

                  Result(Result_Index) := Secondary_Weight;
                  Result_Index := Result_Index + 1;
               end;

               -- Add level separator if more levels follow
               if Settings.Strength >= Tertiary then
                  Result(Result_Index) := Level_Separator;
                  Result_Index := Result_Index + 1;
               end if;
            end if;

            -- Add tertiary weight if strength >= Tertiary
            if Settings.Strength >= Tertiary then
               Result(Result_Index) := Element.Tertiary_Weight;
               Result_Index := Result_Index + 1;

               -- Add level separator if more levels follow
               if Settings.Strength >= Quaternary then
                  Result(Result_Index) := Level_Separator;
                  Result_Index := Result_Index + 1;
               end if;
            end if;

            -- Add quaternary weight if strength >= Quaternary
            if Settings.Strength >= Quaternary then
               -- Handle variable weighting
               declare
                  Quat_Weight : Collation_Weight := Element.Quaternary_Weight;
               begin
                  case Settings.Variable_Weight is
                     when Non_Ignorable =>
                        -- Keep as is
                        null;
                     when Shifted =>
                        if Element.Is_Variable then
                           Quat_Weight := Max_Weight;
                        end if;
                     when Shift_Trimmed =>
                        if Element.Is_Variable then
                           Quat_Weight := 0;
                        end if;
                  end case;

                  Result(Result_Index) := Quat_Weight;
                  Result_Index := Result_Index + 1;
               end;
            end if;
         end loop;

         -- Trim to actual size
         return Result(1 .. Result_Index - 1);
      end;
   exception
      when others =>
         raise Collation_Error with "Failed to form sort key";
   end Form_Sort_Key;

   -- ===================================================================
   --  STEP 4: COMPARE SORT KEYS
   -- ===================================================================

   function Compare_Sort_Keys (
      Key1     : Sort_Key;
      Key2     : Sort_Key;
      Settings : Parametric_Settings := Default_Settings)
     return Integer is

      Max_Len : constant Positive := Positive'Max(Key1'Length, Key2'Length);
   begin
      -- Compare element by element
      for I in 1 .. Max_Len loop
         declare
            W1 : Collation_Weight := (if I <= Key1'Length then Key1(I) else 0);
            W2 : Collation_Weight := (if I <= Key2'Length then Key2(I) else 0);
         begin
            if W1 < W2 then
               return -1;
            elsif W1 > W2 then
               return 1;
            end if;
            -- If equal, continue to next weight
         end;
      end loop;

      -- If all weights are equal, compare lengths
      if Key1'Length < Key2'Length then
         return -1;
      elsif Key1'Length > Key2'Length then
         return 1;
      else
         return 0;
      end if;
   exception
      when others =>
         raise Collation_Error with "Failed to compare sort keys";
   end Compare_Sort_Keys;

   -- ===================================================================
   --  HIGH-LEVEL FUNCTIONS
   -- ===================================================================

   function Compare (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Integer is
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;

      -- Step 1: Normalize
      declare
         Norm1 : Unicode_String := Normalize(Str1, Settings.Normalization);
         Norm2 : Unicode_String := Normalize(Str2, Settings.Normalization);

         -- Step 2: Produce collation elements
         Elems1 : Collation_Element_Array := Produce_Collation_Elements(Norm1, Settings);
         Elems2 : Collation_Element_Array := Produce_Collation_Elements(Norm2, Settings);

         -- Step 3: Form sort keys
         Key1 : Sort_Key := Form_Sort_Key(Elems1, Settings);
         Key2 : Sort_Key := Form_Sort_Key(Elems2, Settings);

         -- Step 4: Compare
         Result : Integer := Compare_Sort_Keys(Key1, Key2, Settings);
      begin
         return Result;
      end;
   exception
      when others =>
         raise Collation_Error with "Comparison failed";
   end Compare;

   procedure Sort (
      Strings  : in out Ada.Containers.Vectors.Vector;
      Settings : Parametric_Settings := Default_Settings) is
   begin
      -- Simple bubble sort for demonstration
      -- In production, use a proper sorting algorithm
      declare
         N : constant Positive := Positive(Strings.Length);
         Temp : Unicode_String;
      begin
         for I in 1 .. N - 1 loop
            for J in 1 .. N - I loop
               declare
                  Str1 : Unicode_String := Ada.Containers.Vectors.Element(Strings, J);
                  Str2 : Unicode_String := Ada.Containers.Vectors.Element(Strings, J + 1);
               begin
                  if Compare(Str1, Str2, Settings) > 0 then
                     -- Swap
                     Temp := Str1;
                     Strings.Replace_Element(J, Str2);
                     Strings.Replace_Element(J + 1, Temp);
                  end if;
               end;
            end loop;
         end loop;
      end;
   exception
      when others =>
         raise Collation_Error with "Sort failed";
   end Sort;

   function Are_Equal (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Boolean is
   begin
      return Compare(Str1, Str2, Settings) = 0;
   end Are_Equal;

   -- ===================================================================
   --  VARIANT-SPECIFIC PROCEDURES
   -- ===================================================================

   -- Preemptive variant: Can terminate early when difference found
   function Compare_Preemptive (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Integer is
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;

      declare
         Norm1 : Unicode_String := Normalize(Str1, Settings.Normalization);
         Norm2 : Unicode_String := Normalize(Str2, Settings.Normalization);

         Elems1 : Collation_Element_Array := Produce_Collation_Elements(Norm1, Settings);
         Elems2 : Collation_Element_Array := Produce_Collation_Elements(Norm2, Settings);

         Max_Len : constant Positive := Positive'Max(Elems1'Length, Elems2'Length);
      begin
         -- Compare element by element, with early termination
         for I in 1 .. Max_Len loop
            declare
               E1 : Collation_Element := (if I <= Elems1'Length then Elems1(I) else Collation_Element'(others => 0));
               E2 : Collation_Element := (if I <= Elems2'Length then Elems2(I) else Collation_Element'(others => 0));
            begin
               -- Check at each strength level
               if Settings.Strength >= Primary and then E1.Primary_Weight /= E2.Primary_Weight then
                  return (if E1.Primary_Weight < E2.Primary_Weight then -1 else 1);
               end if;

               if Settings.Strength >= Secondary then
                  declare
                     S1 : Collation_Weight := E1.Secondary_Weight;
                     S2 : Collation_Weight := E2.Secondary_Weight;
                  begin
                     if Settings.Backward_Accents = On then
                        S1 := Max_Weight - S1;
                        S2 := Max_Weight - S2;
                     end if;

                     if S1 /= S2 then
                        return (if S1 < S2 then -1 else 1);
                     end if;
                  end;
               end if;

               if Settings.Strength >= Tertiary and then E1.Tertiary_Weight /= E2.Tertiary_Weight then
                  return (if E1.Tertiary_Weight < E2.Tertiary_Weight then -1 else 1);
               end if;

               if Settings.Strength >= Quaternary then
                  declare
                     Q1 : Collation_Weight := E1.Quaternary_Weight;
                     Q2 : Collation_Weight := E2.Quaternary_Weight;
                  begin
                     case Settings.Variable_Weight is
                        when Shifted =>
                           if E1.Is_Variable then Q1 := Max_Weight; end if;
                           if E2.Is_Variable then Q2 := Max_Weight; end if;
                        when Shift_Trimmed =>
                           if E1.Is_Variable then Q1 := 0; end if;
                           if E2.Is_Variable then Q2 := 0; end if;
                        when others => null;
                     end case;

                     if Q1 /= Q2 then
                        return (if Q1 < Q2 then -1 else 1);
                     end if;
                  end;
               end if;
            end;
         end loop;

         -- All elements equal, compare lengths
         if Elems1'Length < Elems2'Length then
            return -1;
         elsif Elems1'Length > Elems2'Length then
            return 1;
         else
            return 0;
         end if;
      end;
   exception
      when others =>
         raise Collation_Error with "Preemptive comparison failed";
   end Compare_Preemptive;

   -- Non-preemptive variant: Always processes full strings
   function Compare_Non_Preemptive (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings := Default_Settings)
     return Integer is
   begin
      -- This is the same as the regular Compare, which already processes fully
      return Compare(Str1, Str2, Settings);
   end Compare_Non_Preemptive;

   -- Static tailoring: Use pre-defined tailoring table
   function Compare_Static_Tailored (
      Str1      : Unicode_String;
      Str2      : Unicode_String;
      Tailoring : CET_Maps.Map;
      Settings  : Parametric_Settings := Default_Settings)
     return Integer is

      -- Temporarily replace DUCET with tailoring
      Old_DUCET : CET_Maps.Map := DUCET;
   begin
      -- Save old DUCET
      DUCET := Tailoring;

      declare
         Result : Integer := Compare(Str1, Str2, Settings);
      begin
         -- Restore DUCET
         DUCET := Old_DUCET;
         return Result;
      end;
   exception
      when others =>
         DUCET := Old_DUCET;
         raise;
   end Compare_Static_Tailored;

   -- Dynamic tailoring: Modify settings at runtime
   function Compare_Dynamic_Tailored (
      Str1     : Unicode_String;
      Str2     : Unicode_String;
      Settings : Parametric_Settings)
     return Integer is
   begin
      -- This just uses the provided settings directly
      return Compare(Str1, Str2, Settings);
   end Compare_Dynamic_Tailored;

   -- ===================================================================
   --  STRENGTH LEVEL VARIANTS
   -- ===================================================================

   function Compare_Primary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer is
   begin
      declare
         Settings : Parametric_Settings := Default_Settings;
      begin
         Settings.Strength := Primary;
         return Compare(Str1, Str2, Settings);
      end;
   end Compare_Primary;

   function Compare_Secondary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer is
   begin
      declare
         Settings : Parametric_Settings := Default_Settings;
      begin
         Settings.Strength := Secondary;
         return Compare(Str1, Str2, Settings);
      end;
   end Compare_Secondary;

   function Compare_Tertiary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer is
   begin
      return Compare(Str1, Str2, Default_Settings);
   end Compare_Tertiary;

   function Compare_Quaternary (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer is
   begin
      declare
         Settings : Parametric_Settings := Default_Settings;
      begin
         Settings.Strength := Quaternary;
         return Compare(Str1, Str2, Settings);
      end;
   end Compare_Quaternary;

   -- ===================================================================
   --  VARIABLE WEIGHTING VARIANTS
   -- ===================================================================

   function Compare_Non_Ignorable (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer is
   begin
      declare
         Settings : Parametric_Settings := Default_Settings;
      begin
         Settings.Variable_Weight := Non_Ignorable;
         return Compare(Str1, Str2, Settings);
      end;
   end Compare_Non_Ignorable;

   function Compare_Shifted (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer is
   begin
      declare
         Settings : Parametric_Settings := Default_Settings;
      begin
         Settings.Variable_Weight := Shifted;
         return Compare(Str1, Str2, Settings);
      end;
   end Compare_Shifted;

   function Compare_Shift_Trimmed (
      Str1 : Unicode_String;
      Str2 : Unicode_String)
     return Integer is
   begin
      declare
         Settings : Parametric_Settings := Default_Settings;
      begin
         Settings.Variable_Weight := Shift_Trimmed;
         return Compare(Str1, Str2, Settings);
      end;
   end Compare_Shift_Trimmed;

   -- ===================================================================
   --  VALIDATION FUNCTIONS
   -- ===================================================================

   function Is_Valid_Unicode_String (S : Unicode_String) return Boolean is
   begin
      for C of S loop
         if Character'Pos(C) > 255 then
            -- For simplicity, we accept all characters
            -- In a full implementation, validate proper Unicode
            return False;
         end if;
      end loop;
      return True;
   exception
      when others =>
         return False;
   end Is_Valid_Unicode_String;

   function Is_Valid_Code_Point (CP : Unicode_Code_Point) return Boolean is
   begin
      -- Valid Unicode code points: 0 to 0x10FFFF, excluding surrogates
      return CP <= 16#10FFFF# and then
             (CP < 16#D800# or CP > 16#DFFF#);
   end Is_Valid_Code_Point;

   function Are_Valid_Settings (Settings : Parametric_Settings) return Boolean is
   begin
      -- All settings are valid by construction (enumerated types)
      return True;
   end Are_Valid_Settings;

   function Get_Level_Separator return Collation_Weight is
   begin
      return Level_Separator;
   end Get_Level_Separator;

end Unicode_Collation;
