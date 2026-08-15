with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Vectors;
with Unicode_Collation; use Unicode_Collation;

procedure Main is
   package Unicode_Vectors is new Ada.Containers.Vectors(
      Index_Type => Positive,
      Element_Type => Unicode_String);

   Vec : Unicode_Vectors.Vector;
   Strings : array (1 .. 10) of Unicode_String := (
      "apple", "Apple", "ápple", "banana", "Banana",
      "cherry", "Cherry", "apricot", "Ápple", "123");

begin
   Put_Line("Unicode Collation Algorithm Demo");
   Put_Line("=================================");
   New_Line;

   Initialize_DUCET;

   for S of Strings loop
      Vec.Append(S);
   end loop;

   Put_Line("Sorting with default settings (Tertiary strength):");
   Sort(Vec);
   for I in 1 .. Positive(Vec.Length) loop
      Put_Line(Integer'Image(I) & ". " & Unicode_String'(Vec.Element(I)));
   end loop;
   New_Line;

   Put_Line("Sorting with Primary strength (case-insensitive):");
   declare
      Settings : Parametric_Settings := (Strength => Primary, others => Default_Settings);
   begin
      Sort(Vec, Settings);
      for I in 1 .. Positive(Vec.Length) loop
         Put_Line(Integer'Image(I) & ". " & Unicode_String'(Vec.Element(I)));
      end loop;
   end;
   New_Line;

   Put_Line("Comparison Examples:");
   Put_Line("-------------------");
   declare
      Result : Integer;
   begin
      Result := Compare("apple", "Apple");
      Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) &
         (if Result < 0 then " (apple < Apple)" elsif Result > 0 then " (apple > Apple)" else " (equal)"));

      Result := Compare("apple", "ápple");
      Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) &
         (if Result < 0 then " (apple < ápple)" elsif Result > 0 then " (apple > ápple)" else " (equal)"));

      Result := Compare("123", "abc");
      Put_Line("Compare(""123"", ""abc"") = " & Integer'Image(Result) &
         (if Result < 0 then " (123 < abc)" elsif Result > 0 then " (123 > abc)" else " (equal)"));
   end;

   Put_Line("Demo complete.");
end Main;
