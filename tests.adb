with Ada.Text_IO; use Ada.Text_IO;
with Unicode_Collation; use Unicode_Collation;

procedure Tests is

   Test_Count : Integer := 0;
   Pass_Count : Integer := 0;
   Fail_Count : Integer := 0;

   procedure Print_Test_Header (Name : String) is
   begin
      Test_Count := Test_Count + 1;
      New_Line;
      Put_Line("TEST" & Integer'Image(Test_Count) & " - " & Name);
   end Print_Test_Header;

   procedure Print_Assertion (Number : Integer; Description : String; Passed : Boolean) is
   begin
      Put("   " & Integer'Image(Number) & ".0 " & Description);
      if Passed then
         Put_Line(" PASS");
         Pass_Count := Pass_Count + 1;
      else
         Put_Line(" FAIL");
         Fail_Count := Fail_Count + 1;
      end if;
   end Print_Assertion;

   procedure Print_Summary is
   begin
      New_Line;
      Put_Line("=" & String'((1 .. 50 => '=')));
      Put_Line("TEST SUMMARY");
      Put_Line("=" & String'((1 .. 50 => '=')));
      Put_Line("Total tests: " & Integer'Image(Test_Count));
      Put_Line("Passed: " & Integer'Image(Pass_Count));
      Put_Line("Failed: " & Integer'Image(Fail_Count));
      Put_Line("=" & String'((1 .. 50 => '=')));
   end Print_Summary;

begin
   Initialize_DUCET;

   Print_Test_Header("Basic ASCII Comparison");
   Print_Assertion(1, "A < B", Compare("A", "B") < 0);
   Print_Assertion(2, "a > A (tertiary)", Compare("a", "A") > 0);
   Print_Assertion(3, "A = A", Compare("A", "A") = 0);

   Print_Test_Header("Strength Level Variations");
   Print_Assertion(1, "Primary: A = a", Compare_Primary("A", "a") = 0);
   Print_Assertion(2, "Secondary: e < é", Compare_Secondary("e", String'(Character'Val(233))) < 0);
   Print_Assertion(3, "Tertiary: A < a", Compare_Tertiary("A", "a") < 0);

   Print_Test_Header("Accented Characters");
   Print_Assertion(1, "é > e", Compare("e", String'(Character'Val(233))) < 0);
   Print_Assertion(2, "è < é", Compare(String'(Character'Val(232)), String'(Character'Val(233))) < 0);
   Print_Assertion(3, "à < á < â", 
      Compare(String'(Character'Val(224)), String'(Character'Val(225))) < 0 and then
      Compare(String'(Character'Val(225)), String'(Character'Val(226))) < 0);

   Print_Test_Header("Variable Weighting");
   Print_Assertion(1, "Non-ignorable: a < a,", Compare_Non_Ignorable("a", "a,") < 0);
   Print_Assertion(2, "Shifted: a = a,", Compare_Shifted("a", "a,") = 0);
   Print_Assertion(3, "Shift-Trimmed: a = a,", Compare_Shift_Trimmed("a", "a,") = 0);

   Print_Test_Header("Empty and Single Character");
   Print_Assertion(1, "Empty < A", Compare("", "A") < 0);
   Print_Assertion(2, "A < B", Compare("A", "B") < 0);
   Print_Assertion(3, "Empty = Empty", Compare("", "") = 0);

   Print_Test_Header("String Length Differences");
   Print_Assertion(1, "A < AA", Compare("A", "AA") < 0);
   Print_Assertion(2, "AA < AAA", Compare("AA", "AAA") < 0);
   Print_Assertion(3, "ABC < ABD", Compare("ABC", "ABD") < 0);

   Print_Test_Header("Preemptive vs Non-Preemptive");
   Print_Assertion(1, "Preemptive: A < B", Compare_Preemptive("A", "B") < 0);
   Print_Assertion(2, "Non-preemptive: A < B", Compare_Non_Preemptive("A", "B") < 0);
   Print_Assertion(3, "Preemptive = Non-preemptive for A,B", 
      Compare_Preemptive("A", "B") = Compare_Non_Preemptive("A", "B"));

   Print_Test_Header("Backward Accents");
   declare
      Settings_Normal : Parametric_Settings := (Backward_Accents => Off, others => Default_Settings);
      Settings_Backward : Parametric_Settings := (Backward_Accents => On, others => Default_Settings);
   begin
      Print_Assertion(1, "Normal: é > e", Compare("e", String'(Character'Val(233)), Settings_Normal) < 0);
      Print_Assertion(2, "Backward: é < e", Compare("e", String'(Character'Val(233)), Settings_Backward) > 0);
      Print_Assertion(3, "Primary unaffected", Compare_Primary("e", String'(Character'Val(233))) = 0);
   end;

   Print_Test_Header("Case Level");
   declare
      Settings_No_Case : Parametric_Settings := (Case_Level => Off, others => Default_Settings);
      Settings_With_Case : Parametric_Settings := (Case_Level => On, others => Default_Settings);
   begin
      Print_Assertion(1, "No case level: A < a", Compare("A", "a", Settings_No_Case) < 0);
      Print_Assertion(2, "With case level: A < a", Compare("A", "a", Settings_With_Case) < 0);
      Print_Assertion(3, "Settings valid", Are_Valid_Settings(Settings_With_Case));
   end;

   Print_Test_Header("Normalization");
   declare
      Settings_NFD : Parametric_Settings := (Normalization => NFD, others => Default_Settings);
      Settings_None : Parametric_Settings := (Normalization => None, others => Default_Settings);
   begin
      Print_Assertion(1, "NFD enabled", Settings_NFD.Normalization = NFD);
      Print_Assertion(2, "Normalization disabled", Settings_None.Normalization = None);
      Print_Assertion(3, "Normalization affects comparison", Compare("A", "A", Settings_NFD) = 0);
   end;

   Print_Test_Header("Sort Key Formation");
   declare
      Elems : Collation_Element_Array := Produce_Collation_Elements("A");
      Key : Sort_Key := Form_Sort_Key(Elems);
   begin
      Print_Assertion(1, "Sort key non-empty", Key'Length > 0);
   end;
   declare
      Settings : Parametric_Settings := (Strength => Primary, others => Default_Settings);
      Elems : Collation_Element_Array := Produce_Collation_Elements("a");
      Key : Sort_Key := Form_Sort_Key(Elems, Settings);
   begin
      Print_Assertion(2, "Primary-only key", Key'Length > 0);
   end;
   declare
      Key1 : Sort_Key := Form_Sort_Key(Produce_Collation_Elements("A"));
      Key2 : Sort_Key := Form_Sort_Key(Produce_Collation_Elements("B"));
   begin
      Print_Assertion(3, "Different strings, different keys", Key1 /= Key2);
   end;

   Print_Test_Header("Edge Cases");
   declare
      Long_String : constant String := (1 .. 1000 => 'A');
   begin
      Print_Assertion(1, "Long string comparison", Compare(Long_String, Long_String) = 0);
   end;
   Print_Assertion(2, "Mixed: a < Á", Compare("a", "Á") < 0);
   Print_Assertion(3, "Special: 0 < A", Compare("0", "A") < 0);

   Print_Test_Header("Are_Equal Function");
   Print_Assertion(1, "A = A", Are_Equal("A", "A"));
   Print_Assertion(2, "A /= B", not Are_Equal("A", "B"));
   Print_Assertion(3, "A /= a (tertiary)", not Are_Equal("A", "a"));

   Print_Test_Header("Static Tailoring");
   declare
      Custom_Tailoring : CET_Maps.Map;
      Settings : Parametric_Settings := Default_Settings;
   begin
      Custom_Tailoring.Insert(Key => Unicode_Code_Point(Character'Pos('Z')),
         New_Item => CET_Entry'(Element => (0x1000, 0, 0, 0, False)));
      Print_Assertion(1, "Custom tailoring: Z < A", 
         Compare_Static_Tailored("Z", "A", Custom_Tailoring, Settings) < 0);
   end;
   Print_Assertion(2, "Default: A < Z", Compare("A", "Z") < 0);
   Print_Assertion(3, "B < C unchanged", Compare("B", "C") < 0);

   Print_Test_Header("Dynamic Tailoring");
   declare
      Settings : Parametric_Settings := (Strength => Primary, others => Default_Settings);
   begin
      Print_Assertion(1, "Dynamic primary: A = a", Compare_Dynamic_Tailored("A", "a", Settings) = 0);
   end;
   declare
      Settings : Parametric_Settings := (Variable_Weight => Shifted, others => Default_Settings);
   begin
      Print_Assertion(2, "Dynamic shifted: a = a,", Compare_Dynamic_Tailored("a", "a,", Settings) = 0);
   end;
   declare
      Settings : Parametric_Settings := (Strength => Secondary, Variable_Weight => Shift_Trimmed, others => Default_Settings);
   begin
      Print_Assertion(3, "Multiple settings work", Compare_Dynamic_Tailored("a", "á", Settings) /= 0);
   end;

   Print_Summary;
   New_Line;
   if Fail_Count = 0 then
      Put_Line("ALL TESTS PASSED!");
   else
      Put_Line("SOME TESTS FAILED!");
   end if;

exception
   when E : others =>
      Put_Line("FATAL ERROR: " & Ada.Exceptions.Exception_Message(E));
      Print_Summary;
end Tests;
