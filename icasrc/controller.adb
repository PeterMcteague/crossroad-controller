with HWIF; use HWIF;
with HWIF_Types; use HWIF_Types;
With Ada.Calendar; use Ada.Calendar;

procedure Controller is
   Delays : constant array (1..11) of Duration := (2.0,2.0,5.0,3.0,2.0,2.0,5.0,3.0,2.0,6.0,6.0);
   State : Integer := 1;
   NextState: Integer := 2;
   PreviousState: Integer := 1;
   Time_Next : Ada.Calendar.Time;
   EV_Incoming_NS : Boolean := False;
   EV_Incoming_EW : Boolean := False;

   --Sets the button to change after 0.2 seconds--
   procedure CheckPedestrianButton is
   begin
      if (Pedestrian_Button(North) = 1 or Pedestrian_Button(South) = 1) and State /= 10
         and (Pedestrian_Wait(North) /= 1 and Pedestrian_Wait(South) /= 1) then
         Pedestrian_Wait(North) := 1;
         Pedestrian_Wait(South) := 1;
      end if;
      if (Pedestrian_Button(East) = 1 or Pedestrian_Button(West) = 1) and State /= 11
      and (Pedestrian_Wait(East) /= 1 and Pedestrian_Wait(West) /= 1)then
         Pedestrian_Wait(East) := 1;
         Pedestrian_Wait(West) := 1;
      end if;
   end CheckPedestrianButton;

   procedure CheckEV is
   begin
      if (Emergency_Vehicle_Sensor(North) = 1 or Emergency_Vehicle_Sensor(South) = 1) then
         EV_Incoming_NS := True;
      end if;

      if (Emergency_Vehicle_Sensor(East) = 1 or Emergency_Vehicle_Sensor(West) = 1) then
         EV_Incoming_EW := True;
      end if;
   end CheckEV;

   procedure HoldEV is
      Inner_NextTime: Ada.Calendar.Time;
   begin
      if State = 3 and EV_Incoming_NS then
         while Emergency_Vehicle_Sensor(North) = 1 or Emergency_Vehicle_Sensor(South) = 1 loop
            CheckPedestrianButton;
            CheckEV;
         end loop;
         --Keep the state for 10 seconds more--
         Inner_NextTime := Clock + 10.0;
         while Ada.Calendar.">="(Inner_NextTime, Ada.Calendar.Clock) loop
            CheckPedestrianButton;
            CheckEV;
         end loop;
         EV_Incoming_NS := False;
      end if;

      if State = 7 and EV_Incoming_EW then
         while Emergency_Vehicle_Sensor(East) = 1 or Emergency_Vehicle_Sensor(West) = 1 loop
            CheckPedestrianButton;
            CheckEV;
         end loop;
         --Keep the state for 10 seconds more--
         Inner_NextTime := Clock + 10.0;
         while Ada.Calendar.">="(Inner_NextTime, Ada.Calendar.Clock) loop
            CheckPedestrianButton;
            CheckEV;
         end loop;
         EV_Incoming_EW := False;
      end if;
   end HoldEV;
begin
   Endless_Loop :
   loop
      CheckPedestrianButton;
      CheckEV;

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

      --loop until next state with checks for EV and Pedestriain buttons--
      Time_Next := Clock + Delays(State);
      while Ada.Calendar.">="(Time_Next, Ada.Calendar.Clock) loop
         CheckPedestrianButton;
         CheckEV;
      end loop;

      --Checking for special state actions--
      if (State = 3 and EV_Incoming_NS) or (State = 7 and EV_Incoming_EW) then
         HoldEV;
      end if;

      --Checking what the next state should be--
      case State is

         --If all red--
         when 1 =>
            --When N or S pedestrian buttons pressed and at an all red and there's no EV--
            if (Pedestrian_Wait(North) = 1 or Pedestrian_Wait(South) = 1)
              and (Emergency_Vehicle_Sensor(North) /= 1 and Emergency_Vehicle_Sensor(South) /= 1)
              and (Emergency_Vehicle_Sensor(East) /= 1 and Emergency_Vehicle_Sensor(West) /= 1)
              and (PreviousState /= 10) then
               NextState := 10;
            --When E or W pedestrian buttons pressed and at an all red and there's no EV--
            elsif (Pedestrian_Wait(East) = 1 or Pedestrian_Wait(West) = 1)
              and (Emergency_Vehicle_Sensor(East) /= 1 and Emergency_Vehicle_Sensor(West) /= 1)
              and (Emergency_Vehicle_Sensor(North) /= 1 and Emergency_Vehicle_Sensor(South) /= 1)
              and (PreviousState /= 11) then
               NextState := 11;
            --If we're at all red and there's an EW EV , put EW to RA instead of NS--
            elsif (Emergency_Vehicle_Sensor(East) = 1 or Emergency_Vehicle_Sensor(West) = 1) then
               NextState := 6;
            else
               NextState := State + 1;
            end if;

         --Go back to all red from pedestrian green or end of cycle--
         when 9..11 =>
            NextState := 1;

         when others =>
            NextState := State + 1;
      end case;

      PreviousState := State;
      State := NextState;

   end loop Endless_Loop;
end Controller;

