with Ada.Text_IO; use Ada.Text_IO;
with Unicode_Collation; use Unicode_Collation;

procedure Main is
   Vec : String_Vectors.Vector;

begin
   Put_Line("Unicode Collation Algorithm Demo");
   Put_Line("=================================");
   New_Line;

   Initialize_DUCET;

   String_Vectors.Append(Vec, "apple");
   String_Vectors.Append(Vec, "Apple");
   String_Vectors.Append(Vec, "ápple");
   String_Vectors.Append(Vec, "banana");
   String_Vectors.Append(Vec, "Banana");
   String_Vectors.Append(Vec, "cherry");
   String_Vectors.Append(Vec, "Cherry");
   String_Vectors.Append(Vec, "apricot");
   String_Vectors.Append(Vec, "Ápple");
   String_Vectors.Append(Vec, "123");

   Put_Line("Sorting with default settings (Tertiary strength):");
   Sort(Vec);
   for I in 1 .. Positive(String_Vectors.Length(Vec)) loop
      Put_Line(Integer'Image(I) & ". " & String_Vectors.Element(Vec, I));
   end loop;
   New_Line;

   Put_Line("Sorting with Primary strength (case-insensitive):");
   declare
      Settings : Parametric_Settings := (Primary, Non_Ignorable, Off, Off, NFD);
   begin
      Sort(Vec, Settings);
      for I in 1 .. Positive(String_Vectors.Length(Vec)) loop
         Put_Line(Integer'Image(I) & ". " & String_Vectors.Element(Vec, I));
      end loop;
   end;
   New_Line;

   Put_Line("Comparison Examples:");
   Put_Line("-------------------");
   declare
      Result : Integer;
   begin
      Result := Compare("apple", "Apple");
      if Result < 0 then
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (apple < Apple)");
      elsif Result > 0 then
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (apple > Apple)");
      else
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (equal)");
      end if;

      Result := Compare("apple", "ápple");
      if Result < 0 then
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (apple < ápple)");
      elsif Result > 0 then
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (apple > ápple)");
      else
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (equal)");
      end if;

      Result := Compare("123", "abc");
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
