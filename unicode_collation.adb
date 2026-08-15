with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package body Unicode_Collation is

   Level_Separator : constant Collation_Weight := 0;
   DUCET_Initialized : Boolean := False;
   Max_Weight : constant Collation_Weight := 65535;

   function Unicode_Code_Point_Hash (Key : Unicode_Code_Point) return Ada.Containers.Hash_Type is
   begin
      return Ada.Containers.Hash_Type(Key mod 2**32);
   end Unicode_Code_Point_Hash;

   function Unicode_Code_Point_Equal (Left, Right : Unicode_Code_Point) return Boolean is
   begin
      return Left = Right;
   end Unicode_Code_Point_Equal;

   procedure Initialize_DUCET is
      procedure Add_Entry (CP : Unicode_Code_Point; P, S, T, Q : Collation_Weight; Variable : Boolean := False) is
      begin
         DUCET.Insert(Key => CP, New_Item => CET_Entry'(Element => (P, S, T, Q, Variable)));
      end Add_Entry;
   begin
      if DUCET_Initialized then
         return;
      end if;
      DUCET.Clear;
      Add_Entry(32, 0x0001, 0, 0, 0, True);
      Add_Entry(33, 0x0002, 0, 0, 0, True);
      Add_Entry(34, 0x0003, 0, 0, 0, True);
      Add_Entry(39, 0x0004, 0, 0, 0, True);
      Add_Entry(44, 0x0005, 0, 0, 0, True);
      Add_Entry(45, 0x0006, 0, 0, 0, True);
      Add_Entry(46, 0x0007, 0, 0, 0, True);
      Add_Entry(58, 0x0008, 0, 0, 0, True);
      Add_Entry(59, 0x0009, 0, 0, 0, True);
      for I in 0 .. 9 loop
         Add_Entry(48 + I, 0x0010 + Collation_Weight(I), 0, 0, 0, True);
      end loop;
      for I in 0 .. 25 loop
         Add_Entry(65 + I, 0x2000 + Collation_Weight(I), 0, 2, 0);
      end loop;
      for I in 0 .. 25 loop
         Add_Entry(97 + I, 0x2000 + Collation_Weight(I), 0, 3, 0);
      end loop;
      Add_Entry(233, 0x2004, 0x0020, 0, 0);
      Add_Entry(232, 0x2004, 0x0021, 0, 0);
      Add_Entry(234, 0x2004, 0x0022, 0, 0);
      Add_Entry(227, 0x2000, 0x0020, 0, 0);
      Add_Entry(225, 0x2000, 0x0021, 0, 0);
      Add_Entry(224, 0x2000, 0x0022, 0, 0);
      Add_Entry(196, 0x2000, 0x0023, 2, 0);
      Add_Entry(228, 0x2000, 0x0023, 3, 0);
      Add_Entry(214, 0x2014, 0x0020, 2, 0);
      Add_Entry(246, 0x2014, 0x0020, 3, 0);
      Add_Entry(220, 0x2018, 0x0020, 2, 0);
      Add_Entry(252, 0x2018, 0x0020, 3, 0);
      Add_Entry(223, 0x2019, 0, 0, 0);
      DUCET_Initialized := True;
   exception
      when others =>
         DUCET_Initialized := False;
         raise;
   end Initialize_DUCET;

   function Is_DUCET_Initialized return Boolean is (DUCET_Initialized);

   function Normalize (Input : String; Mode : Normalization_Mode := NFD) return String is
   begin
      if Mode = None then
         return Input;
      end if;
      declare
         Output : Unbounded_String;
      begin
         for I in 1 .. Input'Length loop
            case Input(I) is
               when Character'Val(196) => Append(Output, "A");
               when Character'Val(228) => Append(Output, "a");
               when Character'Val(214) => Append(Output, "O");
               when Character'Val(246) => Append(Output, "o");
               when Character'Val(220) => Append(Output, "U");
               when Character'Val(252) => Append(Output, "u");
               when others => Append(Output, Input(I));
            end case;
         end loop;
         return To_String(Output);
      end;
   exception
      when others => raise Normalization_Error with "Normalization failed";
   end Normalize;

   function To_Code_Points (S : String) return Code_Point_Array is
      Result : Code_Point_Array(1 .. S'Length);
   begin
      for I in S'Range loop
         Result(I) := Unicode_Code_Point(Character'Pos(S(I)));
      end loop;
      return Result;
   exception
      when others => raise Invalid_Code_Point with "Invalid code point in string";
   end To_Code_Points;

   function Get_Collation_Element (Code_Point : Unicode_Code_Point; Table : CET_Maps.Map := DUCET) return Collation_Element is
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;
      if Table.Contains(Key => Code_Point) then
         return Table.Element(Key => Code_Point).Element;
      else
         return (Primary_Weight => Collation_Weight(Code_Point mod 65536), others => 0, Is_Variable => True);
      end if;
   end Get_Collation_Element;

   function Produce_Collation_Elements (Input : String; Settings : Parametric_Settings := Default_Settings) return Collation_Element_Array is
      Normalized : String := Normalize(Input, Settings.Normalization);
      Points     : Code_Point_Array := To_Code_Points(Normalized);
      Result     : Collation_Element_Array(1 .. Points'Length);
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;
      for I in Points'Range loop
         Result(I) := Get_Collation_Element(Points(I), DUCET);
      end loop;
      return Result;
   exception
      when others => raise Collation_Error with "Failed to produce collation elements";
   end Produce_Collation_Elements;

   function Form_Sort_Key (Elements : Collation_Element_Array; Settings : Parametric_Settings := Default_Settings) return Sort_Key is
      Max_Length : constant Positive := Elements'Length * 5;
      Result     : Sort_Key(1 .. Max_Length);
      Result_Index : Positive := 1;
   begin
      if not DUCET_Initialized then
         Initialize_DUCET;
      end if;
      for Element of Elements loop
         if Settings.Strength >= Primary then
            Result(Result_Index) := Element.Primary_Weight;
            Result_Index := Result_Index + 1;
            if Settings.Strength >= Secondary then
               Result(Result_Index) := Level_Separator;
               Result_Index := Result_Index + 1;
            end if;
         end if;
         if Settings.Strength >= Secondary then
            declare
               S : Collation_Weight := Element.Secondary_Weight;
            begin
               if Settings.Backward_Accents = On then
                  S := Max_Weight - S;
               end if;
               Result(Result_Index) := S;
               Result_Index := Result_Index + 1;
            end;
            if Settings.Strength >= Tertiary then
               Result(Result_Index) := Level_Separator;
               Result_Index := Result_Index + 1;
            end if;
         end if;
         if Settings.Strength >= Tertiary then
            Result(Result_Index) := Element.Tertiary_Weight;
            Result_Index := Result_Index + 1;
            if Settings.Strength >= Quaternary then
               Result(Result_Index) := Level_Separator;
               Result_Index := Result_Index + 1;
            end if;
         end if;
         if Settings.Strength >= Quaternary then
            declare
               Q : Collation_Weight := Element.Quaternary_Weight;
            begin
               case Settings.Variable_Weight is
                  when Shifted => if Element.Is_Variable then Q := Max_Weight; end if;
                  when Shift_Trimmed => if Element.Is_Variable then Q := 0; end if;
                  when others => null;
               end case;
               Result(Result_Index) := Q;
               Result_Index := Result_Index + 1;
            end;
         end if;
      end loop;
      return Result(1 .. Result_Index - 1);
   exception
      when others => raise Collation_Error with "Failed to form sort key";
   end Form_Sort_Key;

   function Compare_Sort_Keys (Key1, Key2 : Sort_Key; Settings : Parametric_Settings := Default_Settings) return Integer is
      Max_Len : constant Positive := Positive'Max(Key1'Length, Key2'Length);
   begin
      for I in 1 .. Max_Len loop
         declare
            W1 : Collation_Weight := (if I <= Key1'Length then Key1(I) else 0);
            W2 : Collation_Weight := (if I <= Key2'Length then Key2(I) else 0);
         begin
            if W1 < W2 then return -1;
            elsif W1 > W2 then return 1;
            end if;
         end;
      end loop;
      if Key1'Length < Key2'Length then return -1;
      elsif Key1'Length > Key2'Length then return 1;
      else return 0;
      end if;
   exception
      when others => raise Collation_Error with "Failed to compare sort keys";
   end Compare_Sort_Keys;

   function Compare (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Integer is
      Norm1 : String := Normalize(Str1, Settings.Normalization);
      Norm2 : String := Normalize(Str2, Settings.Normalization);
      Elems1 : Collation_Element_Array := Produce_Collation_Elements(Norm1, Settings);
      Elems2 : Collation_Element_Array := Produce_Collation_Elements(Norm2, Settings);
      Key1 : Sort_Key := Form_Sort_Key(Elems1, Settings);
      Key2 : Sort_Key := Form_Sort_Key(Elems2, Settings);
   begin
      return Compare_Sort_Keys(Key1, Key2, Settings);
   exception
      when others => raise Collation_Error with "Comparison failed";
   end Compare;

   procedure Sort (Strings : in out String_Vectors.Vector; Settings : Parametric_Settings := Default_Settings) is
      N : constant Positive := Positive(Strings.Length);
      Temp : String;
   begin
      for I in 1 .. N - 1 loop
         for J in 1 .. N - I loop
            declare
               Str1 : String := String_Vectors.Element(Strings, J);
               Str2 : String := String_Vectors.Element(Strings, J + 1);
            begin
               if Compare(Str1, Str2, Settings) > 0 then
                  Temp := Str1;
                  Strings.Replace_Element(J, Str2);
                  Strings.Replace_Element(J + 1, Temp);
               end if;
            end;
         end loop;
      end loop;
   exception
      when others => raise Collation_Error with "Sort failed";
   end Sort;

   function Are_Equal (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Boolean is
   begin
      return Compare(Str1, Str2, Settings) = 0;
   end Are_Equal;

   function Compare_Preemptive (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Integer is
      Norm1 : String := Normalize(Str1, Settings.Normalization);
      Norm2 : String := Normalize(Str2, Settings.Normalization);
      Elems1 : Collation_Element_Array := Produce_Collation_Elements(Norm1, Settings);
      Elems2 : Collation_Element_Array := Produce_Collation_Elements(Norm2, Settings);
      Max_Len : constant Positive := Positive'Max(Elems1'Length, Elems2'Length);
   begin
      for I in 1 .. Max_Len loop
         declare
            E1 : Collation_Element := (if I <= Elems1'Length then Elems1(I) else (others => 0));
            E2 : Collation_Element := (if I <= Elems2'Length then Elems2(I) else (others => 0));
         begin
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
                  if S1 /= S2 then return (if S1 < S2 then -1 else 1); end if;
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
                  if Q1 /= Q2 then return (if Q1 < Q2 then -1 else 1); end if;
               end;
            end if;
         end;
      end loop;
      if Elems1'Length < Elems2'Length then return -1;
      elsif Elems1'Length > Elems2'Length then return 1;
      else return 0;
      end if;
   exception
      when others => raise Collation_Error with "Preemptive comparison failed";
   end Compare_Preemptive;

   function Compare_Non_Preemptive (Str1, Str2 : String; Settings : Parametric_Settings := Default_Settings) return Integer is
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Non_Preemptive;

   function Compare_Static_Tailored (Str1, Str2 : String; Tailoring : CET_Maps.Map; Settings : Parametric_Settings := Default_Settings) return Integer is
      Old_DUCET : CET_Maps.Map := DUCET;
   begin
      DUCET := Tailoring;
      declare
         Result : Integer := Compare(Str1, Str2, Settings);
      begin
         DUCET := Old_DUCET;
         return Result;
      end;
   exception
      when others =>
         DUCET := Old_DUCET;
         raise;
   end Compare_Static_Tailored;

   function Compare_Dynamic_Tailored (Str1, Str2 : String; Settings : Parametric_Settings) return Integer is
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Dynamic_Tailored;

   function Compare_Primary (Str1, Str2 : String) return Integer is
      Settings : Parametric_Settings := (Primary, Non_Ignorable, Off, Off, NFD);
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Primary;

   function Compare_Secondary (Str1, Str2 : String) return Integer is
      Settings : Parametric_Settings := (Secondary, Non_Ignorable, Off, Off, NFD);
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Secondary;

   function Compare_Tertiary (Str1, Str2 : String) return Integer is
   begin
      return Compare(Str1, Str2, Default_Settings);
   end Compare_Tertiary;

   function Compare_Quaternary (Str1, Str2 : String) return Integer is
      Settings : Parametric_Settings := (Quaternary, Non_Ignorable, Off, Off, NFD);
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Quaternary;

   function Compare_Non_Ignorable (Str1, Str2 : String) return Integer is
      Settings : Parametric_Settings := (Tertiary, Non_Ignorable, Off, Off, NFD);
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Non_Ignorable;

   function Compare_Shifted (Str1, Str2 : String) return Integer is
      Settings : Parametric_Settings := (Tertiary, Shifted, Off, Off, NFD);
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Shifted;

   function Compare_Shift_Trimmed (Str1, Str2 : String) return Integer is
      Settings : Parametric_Settings := (Tertiary, Shift_Trimmed, Off, Off, NFD);
   begin
      return Compare(Str1, Str2, Settings);
   end Compare_Shift_Trimmed;

   function Is_Valid_Code_Point (CP : Unicode_Code_Point) return Boolean is
   begin
      return CP <= 16#10FFFF# and then (CP < 16#D800# or CP > 16#DFFF#);
   end Is_Valid_Code_Point;

   function Are_Valid_Settings (Settings : Parametric_Settings) return Boolean is
   begin
      return True;
   end Are_Valid_Settings;

   function Get_Level_Separator return Collation_Weight is (Level_Separator);

   package String_Vectors is new Ada.Containers.Vectors(
      Index_Type => Positive,
      Element_Type => String);

end Unicode_Collation;
