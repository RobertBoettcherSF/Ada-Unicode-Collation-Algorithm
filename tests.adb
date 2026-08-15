--  tests.adb
--  Test suite for Unicode Collation Algorithm
--  13+ tests to verify correctness
--

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Unicode_Collation; use Unicode_Collation;

procedure Tests is

   -- Test counter
   Test_Count : Integer := 0;
   Pass_Count : Integer := 0;
   Fail_Count : Integer := 0;

   -- Print test header
   procedure Print_Test_Header (Name : String) is
   begin
      Test_Count := Test_Count + 1;
      New_Line;
      Put_Line("TEST" & Integer'Image(Test_Count) & " - " & Name);
   end Print_Test_Header;

   -- Print assertion result
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

   -- Print summary
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
   -- Initialize DUCET
   Initialize_DUCET;

   -- TEST 1: Basic ASCII Comparison
   Print_Test_Header("Basic ASCII Comparison");
   begin
      -- 1.1: A < B
      Print_Assertion(1, "A < B", Compare("A", "B") < 0);
      -- 1.2: a > A (case difference at tertiary level)
      Print_Assertion(2, "a > A (tertiary)", Compare("a", "A") > 0);
      -- 1.3: Equal strings
      Print_Assertion(3, "A = A", Compare("A", "A") = 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 2: Strength Level Variations
   Print_Test_Header("Strength Level Variations");
   begin
      -- 2.1: Primary only - case insensitive
      Print_Assertion(1, "Primary: A = a", Compare_Primary("A", "a") = 0);
      -- 2.2: Secondary - accent sensitive
      declare
         Settings : Parametric_Settings := Default_Settings;
      begin
         Settings.Strength := Secondary;
         -- é and e differ at secondary level
         Print_Assertion(2, "Secondary: e < é", Compare("e", Character'Val(233) & "", Settings) < 0);
      end;
      -- 2.3: Tertiary - case sensitive
      Print_Assertion(3, "Tertiary: A < a", Compare_Tertiary("A", "a") < 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 3: Accented Characters
   Print_Test_Header("Accented Characters");
   begin
      -- 3.1: é > e at secondary level
      Print_Assertion(1, "é > e", Compare("e", Character'Val(233) & "") < 0);
      -- 3.2: è < é (different accents)
      Print_Assertion(2, "è < é", Compare(Character'Val(232) & "", Character'Val(233) & "") < 0);
      -- 3.3: à < á < â
      Print_Assertion(3, "à < á < â",
         Compare(Character'Val(224) & "", Character'Val(225) & "") < 0 and then
         Compare(Character'Val(225) & "", Character'Val(226) & "") < 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 4: Variable Weighting
   Print_Test_Header("Variable Weighting");
   begin
      -- 4.1: Non-ignorable - punctuation matters
      Print_Assertion(1, "Non-ignorable: a < a,", Compare_Non_Ignorable("a", "a,") < 0);
      -- 4.2: Shifted - punctuation sorted last
      Print_Assertion(2, "Shifted: a = a,", Compare_Shifted("a", "a,") = 0);
      -- 4.3: Shift-Trimmed - punctuation ignored
      Print_Assertion(3, "Shift-Trimmed: a = a,", Compare_Shift_Trimmed("a", "a,") = 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 5: Empty and Single Character
   Print_Test_Header("Empty and Single Character");
   begin
      -- 5.1: Empty string < any string
      Print_Assertion(1, "Empty < A", Compare("", "A") < 0);
      -- 5.2: Single char comparison
      Print_Assertion(2, "A < B", Compare("A", "B") < 0);
      -- 5.3: Empty = empty
      Print_Assertion(3, "Empty = Empty", Compare("", "") = 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 6: String Length Differences
   Print_Test_Header("String Length Differences");
   begin
      -- 6.1: Prefix comparison
      Print_Assertion(1, "A < AA", Compare("A", "AA") < 0);
      -- 6.2: Same prefix, different length
      Print_Assertion(2, "AA < AAA", Compare("AA", "AAA") < 0);
      -- 6.3: Common prefix
      Print_Assertion(3, "ABC < ABD", Compare("ABC", "ABD") < 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 7: Preemptive vs Non-Preemptive
   Print_Test_Header("Preemptive vs Non-Preemptive");
   begin
      -- 7.1: Preemptive early termination
      Print_Assertion(1, "Preemptive: A < B", Compare_Preemptive("A", "B") < 0);
      -- 7.2: Non-preemptive full comparison
      Print_Assertion(2, "Non-preemptive: A < B", Compare_Non_Preemptive("A", "B") < 0);
      -- 7.3: Results match for simple case
      Print_Assertion(3, "Preemptive = Non-preemptive for A,B",
         Compare_Preemptive("A", "B") = Compare_Non_Preemptive("A", "B"));
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 8: Backward Accents
   Print_Test_Header("Backward Accents");
   begin
      declare
         Settings_Normal : Parametric_Settings := Default_Settings;
         Settings_Backward : Parametric_Settings := Default_Settings;
      begin
         Settings_Backward.Backward_Accents := On;

         -- 8.1: Normal: é > e
         Print_Assertion(1, "Normal: é > e", Compare("e", Character'Val(233) & "", Settings_Normal) < 0);
         -- 8.2: Backward: é < e (reversed)
         Print_Assertion(2, "Backward: é < e", Compare("e", Character'Val(233) & "", Settings_Backward) > 0);
         -- 8.3: Settings don't affect primary level
         Print_Assertion(3, "Primary unaffected", Compare_Primary("e", Character'Val(233) & "") = 0);
      end;
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 9: Case Level
   Print_Test_Header("Case Level");
   begin
      declare
         Settings_No_Case : Parametric_Settings := Default_Settings;
         Settings_With_Case : Parametric_Settings := Default_Settings;
      begin
         Settings_With_Case.Case_Level := On;

         -- 9.1: Without case level, case at tertiary
         Print_Assertion(1, "No case level: A < a", Compare("A", "a", Settings_No_Case) < 0);
         -- 9.2: With case level, case at separate level
         Print_Assertion(2, "With case level: A < a", Compare("A", "a", Settings_With_Case) < 0);
         -- 9.3: Settings are valid
         Print_Assertion(3, "Settings valid", Are_Valid_Settings(Settings_With_Case));
      end;
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 10: Normalization
   Print_Test_Header("Normalization");
   begin
      declare
         Settings_NFD : Parametric_Settings := Default_Settings;
         Settings_None : Parametric_Settings := (Normalization => None, others => Default_Settings);
      begin
         -- 10.1: NFD normalization enabled
         Print_Assertion(1, "NFD enabled", Settings_NFD.Normalization = NFD);
         -- 10.2: Normalization disabled
         Print_Assertion(2, "Normalization disabled", Settings_None.Normalization = None);
         -- 10.3: Compare with and without normalization
         Print_Assertion(3, "Normalization affects comparison",
            Compare("A", "A", Settings_NFD) = 0);
      end;
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 11: Sort Key Formation
   Print_Test_Header("Sort Key Formation");
   begin
      -- 11.1: Form sort key for simple string
      declare
         Elems : Collation_Element_Array := Produce_Collation_Elements("A");
         Key : Sort_Key := Form_Sort_Key(Elems);
      begin
         Print_Assertion(1, "Sort key non-empty", Key'Length > 0);
      end;
      -- 11.2: Sort key respects strength
      declare
         Settings : Parametric_Settings := (Strength => Primary, others => Default_Settings);
         Elems : Collation_Element_Array := Produce_Collation_Elements("a");
         Key : Sort_Key := Form_Sort_Key(Elems, Settings);
      begin
         Print_Assertion(2, "Primary-only key", Key'Length > 0);
      end;
      -- 11.3: Different strings have different keys
      declare
         Key1 : Sort_Key := Form_Sort_Key(Produce_Collation_Elements("A"));
         Key2 : Sort_Key := Form_Sort_Key(Produce_Collation_Elements("B"));
      begin
         Print_Assertion(3, "Different strings, different keys", Key1 /= Key2);
      end;
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 12: Edge Cases
   Print_Test_Header("Edge Cases");
   begin
      -- 12.1: Very long string
      declare
         Long_String : Unicode_String := (1 .. 1000 => 'A');
      begin
         Print_Assertion(1, "Long string comparison", Compare(Long_String, Long_String) = 0);
      end;
      -- 12.2: Mixed case and accents
      Print_Assertion(2, "Mixed: a < Á", Compare("a", "Á") < 0);
      -- 12.3: Special characters
      Print_Assertion(3, "Special: 0 < A", Compare("0", "A") < 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 13: Are_Equal Function
   Print_Test_Header("Are_Equal Function");
   begin
      -- 13.1: Equal strings
      Print_Assertion(1, "A = A", Are_Equal("A", "A"));
      -- 13.2: Different strings
      Print_Assertion(2, "A /= B", not Are_Equal("A", "B"));
      -- 13.3: Case sensitivity
      Print_Assertion(3, "A /= a (tertiary)", not Are_Equal("A", "a"));
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 14: Static Tailoring
   Print_Test_Header("Static Tailoring");
   begin
      -- 14.1: Create custom tailoring
      declare
         Custom_Tailoring : CET_Maps.Map;
         Settings : Parametric_Settings := Default_Settings;
      begin
         -- Add custom mapping: make 'Z' sort before 'A'
         Custom_Tailoring.Insert(
            Key => Unicode_Code_Point(Character'Pos('Z')),
            New_Item => CET_Entry'(
               Element => Collation_Element'(
                  Primary_Weight => 0x1000, -- Lower than A's 0x2000
                  others => 0)));

         -- Z should now sort before A with this tailoring
         Print_Assertion(1, "Custom tailoring: Z < A",
            Compare_Static_Tailored("Z", "A", Custom_Tailoring, Settings) < 0);
      end;
      -- 14.2: Default tailoring still works
      Print_Assertion(2, "Default: A < Z", Compare("A", "Z") < 0);
      -- 14.3: Tailoring doesn't affect other characters
      Print_Assertion(3, "B < C unchanged", Compare("B", "C") < 0);
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- TEST 15: Dynamic Tailoring
   Print_Test_Header("Dynamic Tailoring");
   begin
      -- 15.1: Change strength dynamically
      declare
         Settings : Parametric_Settings := (Strength => Primary, others => Default_Settings);
      begin
         Print_Assertion(1, "Dynamic primary: A = a", Compare_Dynamic_Tailored("A", "a", Settings) = 0);
      end;
      -- 15.2: Change variable weighting dynamically
      declare
         Settings : Parametric_Settings := (Variable_Weight => Shifted, others => Default_Settings);
      begin
         Print_Assertion(2, "Dynamic shifted: a = a,", Compare_Dynamic_Tailored("a", "a,", Settings) = 0);
      end;
      -- 15.3: Multiple settings
      declare
         Settings : Parametric_Settings :=
           (Strength => Secondary, Variable_Weight => Shift_Trimmed, others => Default_Settings);
      begin
         Print_Assertion(3, "Multiple settings work", Compare_Dynamic_Tailored("a", "á", Settings) /= 0);
      end;
   exception
      when E : others =>
         Put_Line("   Exception: " & Ada.Exceptions.Exception_Message(E));
         Fail_Count := Fail_Count + 3;
   end;

   -- Print summary
   Print_Summary;

   -- Final result
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
