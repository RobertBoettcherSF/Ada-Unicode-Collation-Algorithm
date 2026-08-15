--  main.adb
--  Example usage of Unicode Collation Algorithm
--

with Ada.Text_IO; use Ada.Text_IO;
with Unicode_Collation; use Unicode_Collation;

procedure Main is
   -- Example strings to sort
   type String_Access is access Unicode_String;
   Strings : array (1 .. 10) of String_Access := (
      new Unicode_String'("apple"),
      new Unicode_String'("Apple"),
      new Unicode_String'("ápple"),
      new Unicode_String'("banana"),
      new Unicode_String'("Banana"),
      new Unicode_String'("cherry"),
      new Unicode_String'("Cherry"),
      new Unicode_String'("apricot"),
      new Unicode_String'("Ápple"),
      new Unicode_String'("123")
   );

   -- Sort the strings
   package Unicode_Vectors is new Ada.Containers.Vectors(
      Index_Type => Positive,
      Element_Type => Unicode_String);

   Vec : Unicode_Vectors.Vector;
begin
   Put_Line("Unicode Collation Algorithm Demo");
   Put_Line("=================================");
   New_Line;

   -- Initialize DUCET
   Initialize_DUCET;

   -- Add strings to vector
   for S of Strings loop
      Vec.Append(S.all);
   end loop;

   -- Sort with default settings
   Put_Line("Sorting with default settings (Tertiary strength):");
   Sort(Vec);

   -- Display sorted strings
   for I in 1 .. Positive(Vec.Length) loop
      Put_Line(Integer'Image(I) & ". " & Unicode_String'(Vec.Element(I)));
   end loop;
   New_Line;

   -- Sort with primary strength only (case-insensitive)
   Put_Line("Sorting with Primary strength (case-insensitive):");
   declare
      Settings : Parametric_Settings := Default_Settings;
   begin
      Settings.Strength := Primary;
      Sort(Vec, Settings);

      for I in 1 .. Positive(Vec.Length) loop
         Put_Line(Integer'Image(I) & ". " & Unicode_String'(Vec.Element(I)));
      end loop;
   end;
   New_Line;

   -- Comparison examples
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

   -- Free memory
   for S of Strings loop
      Free(S);
   end loop;

   Put_Line("Demo complete.");
end Main;
