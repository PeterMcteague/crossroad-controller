with HWIF; use HWIF;
with HWIF_Types; use HWIF_Types;
With Ada.Calendar; use Ada.Calendar;

procedure Controller is
   subtype StateInt is Integer range 1..13;

   Delays : constant array (1..13) of Duration := (0.5,6.0,0.5,0.5,5.0,3.0,0.5,6.0,0.5,0.5,5.0,3.0,0.5); --Manages lengths of states--
   ScanRate : constant Duration := 0.2; --The time between looping checks to reduce cpu usage--
   State : StateInt := 1; --The start state--
   NextState: StateInt; --The state to swap to after state--
   Time_Next : Ada.Calendar.Time; --Stores a calendar time, used for delays--
   EV_Incoming_NS : Boolean := False; --Whether an emergency vehicle is incoming--
   EV_Incoming_EW : Boolean := False;

   --Checks whether a pedestrian button has been pressed--
   procedure CheckPedestrianButton is
   begin
      --If the north or south buttons been pressed and the green pedestrian light isn't on and the wait light isn't already on, turn the wait light on--
      if (Pedestrian_Button(North) = 1 or Pedestrian_Button(South) = 1) and State /= 2
         and (Pedestrian_Wait(North) /= 1 and Pedestrian_Wait(South) /= 1) then
         Pedestrian_Wait(North) := 1;
         Pedestrian_Wait(South) := 1;
      end if;
      --If the east or west buttons been pressed and the green pedestrian light isn't on and the wait light isn't already on, turn the wait light on--
      if (Pedestrian_Button(East) = 1 or Pedestrian_Button(West) = 1) and State /= 8
      and (Pedestrian_Wait(East) /= 1 and Pedestrian_Wait(West) /= 1)then
         Pedestrian_Wait(East) := 1;
         Pedestrian_Wait(West) := 1;
      end if;
   end CheckPedestrianButton;

   --If the emergency vehicle sensors pick something up, mark an EV as incoming--
   procedure CheckEV is
   begin
      if (Emergency_Vehicle_Sensor(North) = 1 or Emergency_Vehicle_Sensor(South) = 1) then
         EV_Incoming_NS := True;
      end if;

      if (Emergency_Vehicle_Sensor(East) = 1 or Emergency_Vehicle_Sensor(West) = 1) then
         EV_Incoming_EW := True;
      end if;
   end CheckEV;

   --If there's a emergency vehicle hold this state--
   procedure HoldEV is
      Inner_NextTime: Ada.Calendar.Time;
   begin
      --If we're on green for NS and there's an EV incoming
      if State = 5 and EV_Incoming_NS then
         --Stay until it's gone--
         while Emergency_Vehicle_Sensor(North) = 1 or Emergency_Vehicle_Sensor(South) = 1 loop
            CheckPedestrianButton;
            CheckEV;
            Delay(ScanRate);
         end loop;
         --Keep the state for 10 seconds more--
         Inner_NextTime := Clock + 10.0;
         while Ada.Calendar.">="(Inner_NextTime, Ada.Calendar.Clock) loop
            CheckPedestrianButton;
            CheckEV;
            Delay(ScanRate);
         end loop;
         --Mark that there's no longer an EV incoming--
         EV_Incoming_NS := False;
      end if;

      --If we're on green for EW and there's an EV incoming
      if State = 11 and EV_Incoming_EW then
         --Stay until it's gone--
         while Emergency_Vehicle_Sensor(East) = 1 or Emergency_Vehicle_Sensor(West) = 1 loop
            CheckPedestrianButton;
            CheckEV;
            Delay(ScanRate);
         end loop;
         --Keep the state for 10 seconds more--
         Inner_NextTime := Clock + 10.0;
         while Ada.Calendar.">="(Inner_NextTime, Ada.Calendar.Clock) loop
            CheckPedestrianButton;
            CheckEV;
            Delay(ScanRate);
         end loop;
         --Mark that there's no longer an EV incoming--
         EV_Incoming_EW := False;
      end if;
   end HoldEV;

begin
   Endless_Loop :
   loop
      --Check for buttons and emergency vehicles right off--
      CheckPedestrianButton;
      CheckEV;

      --Change lights depending on state / set state--
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

         when 2 => --NS Pedestrians G--
            Pedestrian_Light(North) := 1;
            Pedestrian_Light(South) := 1;
            Pedestrian_Wait(North) := 0;
            Pedestrian_Wait(South) := 0;

         when 3 => --NS Pedestrians R--
            Pedestrian_Light(North) := 2;
            Pedestrian_Light(South) := 2;

         when 4 => --NS RA--
            Traffic_Light(North) := 6;
            Traffic_Light(South) := 6;

         when 5 => --NS G--
            Traffic_Light(North) := 1;
            Traffic_Light(South) := 1;

         when 6 => --NS A--
            Traffic_Light(North) := 2;
            Traffic_Light(South) := 2;

         when 7 => --NS R--
            Traffic_Light(North) := 4;
            Traffic_Light(South) := 4;

         when 8 => --EW Pedestrians G--
            Pedestrian_Light(East) := 1;
            Pedestrian_Light(West) := 1;
            Pedestrian_Wait(East) := 0;
            Pedestrian_Wait(West) := 0;

         when 9 => --EW Pedestrians R--
            Pedestrian_Light(East) := 2;
            Pedestrian_Light(West) := 2;

         when 10 => --EW RA--
            Traffic_Light(East) := 6;
            Traffic_Light(West) := 6;

         when 11 => --EW G--
            Traffic_Light(East) := 1;
            Traffic_Light(West) := 1;

         when 12 => --EW A--
            Traffic_Light(East) := 2;
            Traffic_Light(West) := 2;

         when 13 => --EW R--
            Traffic_Light(East) := 4;
            Traffic_Light(West) := 4;
      end case;

      --Check if we should hold the state for an emergency vehicle--
      if (State = 5 and EV_Incoming_NS) or (State = 11 and EV_Incoming_EW) then
         HoldEV;
      else
         --Wait for set state length whilst checks for EV and Pedestriain buttons--
         Time_Next := Clock + Delays(State);
         while Ada.Calendar.">="(Time_Next, Ada.Calendar.Clock) loop
            CheckPedestrianButton;
            CheckEV;
            Delay(ScanRate);
         end loop;
      end if;

      --Checking what the next state should be--
      case State is

         --If all red--
         when 1 =>
            if EV_Incoming_EW then
               NextState := 10;
            elsif EV_Incoming_NS then
               NextState := 4;
            elsif (Pedestrian_Wait(North) = 1 and Pedestrian_Wait(South) = 1)
              and EV_Incoming_NS = False and EV_Incoming_EW = False then
               NextState := 2;
            else
               NextState := 4;
            end if;

         when 3 =>
            if EV_Incoming_EW then
               NextState := 10;
            else
               NextState := 4;
            end if;

         when 9 =>
            if EV_Incoming_NS then
               NextState := 4;
            else
               NextState := 10;
            end if;

         --If NS red--
         when 7 =>
            if EV_Incoming_NS then
               NextState := 4;
            elsif EV_Incoming_EW then
               NextState := 10;
            elsif (Pedestrian_Wait(East) = 1 and Pedestrian_Wait(West) = 1)
              and EV_Incoming_NS = False and EV_Incoming_EW = False then
               NextState := 8;
            else
               NextState := 10;
            end if;

         --If EW red--
         when 13 =>
            if EV_Incoming_EW then
               NextState := 10;
            elsif EV_Incoming_NS then
               NextState := 4;
            elsif (Pedestrian_Wait(North) = 1 and Pedestrian_Wait(South) = 1)
               and EV_Incoming_NS = False and EV_Incoming_EW = False then
               NextState := 2;
            else
               NextState := 4;
            end if;

         when others =>
            NextState := State + 1;
      end case;

      State := NextState;

   end loop Endless_Loop;
end Controller;

