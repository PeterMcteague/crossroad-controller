with HWIF; use HWIF;
with HWIF_Types; use HWIF_Types;

procedure Controller is
   Delays : constant array (1..11) of Duration := (2.0,2.0,5.0,3.0,2.0,2.0,5.0,3.0,2.0,6.0,6.0);

   State : Integer := 1;
   NextState: Integer;
begin
   Endless_Loop :
   loop
      case State is
         when 1 => --All red--
            Traffic_Light(North) := 4;
            Traffic_Light(East) := 4;
            Traffic_Light(South) := 4;
            Traffic_Light(West) := 4;
            Pedestrian_Light(North) := 2;
            Pedestrian_Light(East) := 2;
            Pedestrian_Light(South) := 2;
            Pedestrian_Light(West) := 2;

         when 2 => --NS RA--
            Traffic_Light(North) := 6;
            Traffic_Light(South) := 6;

         when 3 => --NS G--
            Traffic_Light(North) := 1;
            Traffic_Light(South) := 1;

            --If emergency-
            if Emergency_Vehicle_Sensor(North) = 1 or Emergency_Vehicle_Sensor(South) = 1 then
               while Emergency_Vehicle_Sensor(North) = 1 or Emergency_Vehicle_Sensor(South) = 1 loop
                  null; --I'm not looking to do anything, just hold it here
               end loop;
               delay 10.0;
            end if;

         when 4 => --NS A--
            Traffic_Light(North) := 2;
            Traffic_Light(South) := 2;

         when 5 => --NS R--
            Traffic_Light(North) := 4;
            Traffic_Light(South) := 4;

         when 6 => --EW RA--
            Traffic_Light(East) := 6;
            Traffic_Light(West) := 6;

         when 7 => --EW G--
            Traffic_Light(East) := 1;
            Traffic_Light(West) := 1;

            --If emergency-
            if Emergency_Vehicle_Sensor(East) = 1 or Emergency_Vehicle_Sensor(West) = 1 then
               while Emergency_Vehicle_Sensor(East) = 1 or Emergency_Vehicle_Sensor(West) = 1 loop
                  null; --I'm not looking to do anything, just hold it here
               end loop;
               delay 10.0;
            end if;

         when 8 => --EW A--
            Traffic_Light(East) := 2;
            Traffic_Light(West) := 2;

         when 9 => --EW R--
            Traffic_Light(East) := 4;
            Traffic_Light(West) := 4;

         --The below states are out of cycle. These are reached conditionally.

         when 10 => --NS Pedestrian lights G--
            Pedestrian_Light(North) := 1;
            Pedestrian_Light(South) := 1;
            Pedestrian_Wait(North) := 0;
            Pedestrian_Wait(South) := 0;

         when 11 => --EW Pedestrian lights G--
            Pedestrian_Light(East) := 1;
            Pedestrian_Light(West) := 1;
            Pedestrian_Wait(East) := 0;
            Pedestrian_Wait(West) := 0;

         when others =>
            null;
      end case;

      --Checking what the next state should be--
      case State is

         when 1 =>
            --When N or S pedestrian buttons pressed and at an all red--
            if (Pedestrian_Button(North) = 1 or Pedestrian_Button(South) = 1)
              and (Emergency_Vehicle_Sensor(North) /= 1 and Emergency_Vehicle_Sensor(South) /= 1) then
               NextState := 10;
            --When E or W pedestrian buttons pressed and at an all red--
            elsif (Pedestrian_Button(East) = 1 or Pedestrian_Button(West) = 1)
              and (Emergency_Vehicle_Sensor(East) /= 1 and Emergency_Vehicle_Sensor(West) /= 1)then
               NextState := 11;
            end if;

         when 9 =>
            NextState := 1;

         --Go back to all red from pedestrian green
         when 10..11 =>
            NextState := 1;

         when others =>
            if Pedestrian_Button(North) = 1 or Pedestrian_Button(South) = 1 then
               Pedestrian_Wait(North) := 1;
               Pedestrian_Wait(South) := 1;
            elsif Pedestrian_Button(East) = 1 or Pedestrian_Button(West) = 1 then
               Pedestrian_Wait(East) := 1;
               Pedestrian_Wait(West) := 1;
            else
               NextState := State + 1;
            end if;
   end case;

   --Delay for length of state and then swap to the next state--
   delay Delays(state);
   State := NextState;

   end loop Endless_Loop;
end Controller;

