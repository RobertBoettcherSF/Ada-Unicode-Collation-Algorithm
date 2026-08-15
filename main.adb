with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Vectors;
with Unicode_Collation; use Unicode_Collation;

procedure Main is
   package String_Vectors is new Ada.Containers.Vectors(
      Index_Type => Positive,
      Element_Type => String);

   Vec : String_Vectors.Vector;

   function To_US (S : String) return Unicode_String is
   begin
      return Unicode_String(S);
   end To_US;

begin
   Put_Line("Unicode Collation Algorithm Demo");
   Put_Line("=================================");
   New_Line;

   Initialize_DUCET;

   Vec.Append("apple");
   Vec.Append("Apple");
   Vec.Append("ápple");
   Vec.Append("banana");
   Vec.Append("Banana");
   Vec.Append("cherry");
   Vec.Append("Cherry");
   Vec.Append("apricot");
   Vec.Append("Ápple");
   Vec.Append("123");

   Put_Line("Sorting with default settings (Tertiary strength):");
   declare
      US_Vec : Ada.Containers.Vectors.Vector;
   begin
      for I in 1 .. Positive(Vec.Length) loop
         US_Vec.Append(To_US(Vec.Element(I)));
      end loop;
      Sort(US_Vec);
      for I in 1 .. Positive(US_Vec.Length) loop
         Put_Line(Integer'Image(I) & ". " & String(Unicode_String'(US_Vec.Element(I))));
      end loop;
   end;
   New_Line;

   Put_Line("Sorting with Primary strength (case-insensitive):");
   declare
      US_Vec : Ada.Containers.Vectors.Vector;
      Settings : Parametric_Settings := (Strength => Primary, others => Default_Settings);
   begin
      for I in 1 .. Positive(Vec.Length) loop
         US_Vec.Append(To_US(Vec.Element(I)));
      end loop;
      Sort(US_Vec, Settings);
      for I in 1 .. Positive(US_Vec.Length) loop
         Put_Line(Integer'Image(I) & ". " & String(Unicode_String'(US_Vec.Element(I))));
      end loop;
   end;
   New_Line;

   Put_Line("Comparison Examples:");
   Put_Line("-------------------");
   declare
      Result : Integer;
   begin
      Result := Compare(To_US("apple"), To_US("Apple"));
      if Result < 0 then
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (apple < Apple)");
      elsif Result > 0 then
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (apple > Apple)");
      else
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (equal)");
      end if;

      Result := Compare(To_US("apple"), To_US("ápple"));
      if Result < 0 then
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (apple < ápple)");
      elsif Result > 0 then
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (apple > ápple)");
      else
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (equal)");
      end if;

      Result := Compare(To_US("123"), To_US("abc"));
      if Result < 0 then
         Put_Line("Compare(""123"", ""abc"") = " & Integer'Image(Result) & " (123 < abc)");
      elsif Result > 0 then
         Put_Line("Compare(""123"", ""abc"") = " & Integer'Image(Result) & " (123 > abc)");
      else
         Put_Line("Compare(""123"", ""abc"") = " & Integer'Image(Result) & " (equal)");
      end if;
   end;

   Put_Line("Demo complete.");
end Main;
