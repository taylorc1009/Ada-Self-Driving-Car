with WorldPackage; use WorldPackage;
with Ada.Text_IO; use Ada.Text_IO;
with RandGen; use RandGen;

procedure Main is
   inputStr : String(1..2);
   inputLast : Natural := 1;
   turnIncoming : Boolean := False;
   endJourney : Boolean := False;
   task Controller;
   task Driving is
      pragma Priority(10);
   end Driving;

   task body Controller is
   begin
      loop
         Put_Line("Car condition:");
         Put_Line(" - Engine: "& (if car.engineOn then "ON" else "OFF"));
         Put_Line(" - Gear: "& car.gear'Image);
         Put_Line(" - Diagnostics Mode: "& (if car.diagnosticsOn then "ON" else "OFF"));
         Put_Line(" - Battery Level: "& car.battery'Image);
         Put_Line(" - Current Speed: "& car.speed'Image);
         Put_Line("");
         Put_Line("Please select an option for the car to do:");
         Put_Line(" - 0 = toggle engine");
         Put_Line(" - 1 = change gear");
         Get_Line(inputStr, inputLast);

         case inputStr(1) is
            when '0' =>
               engineSwitch;
               Put_Line("Engine: "& (if car.engineOn then "ON" else "OFF"));
            when '1' =>
               Put_Line("Enter a number to put the car into:");
               Put_Line(" - 0 = drive");
               Put_Line(" - 1 = reverse");
               Put_Line(" - 2 = parked");
               <<select_gear>>
               Get_Line(inputStr, inputLast);
               case inputStr(1) is
               when '0' =>
                  changeGear(DRIVE);
               when '1' =>
                  changeGear(REVERSING);
               when '2' =>
                  changeGear(PARKED);
               when others =>
                  Put_Line("(!) error: invalid entry, please enter a number within the given range");
                  goto select_gear;
               end case;
               Put_Line("Gear: "& car.gear'Image);
               initialiseRoute;
            when others =>
               abort Driving;
               exit;
         end case;
         Put_Line("");
      end loop;
   end Controller;

   task body Driving is
   begin
      loop
         if car.engineOn and car.gear /= PARKED then
            if not turnIncoming and not endJourney then
               case generateScenario is
                  when ARRIVED =>
                     Put_Line("Car arrived at destination! Preparing to park...");
                     endJourney := True;
                  when TURN =>
                     Put_Line("Upcoming turn: slowing down to prepare for the turn...");
                     turnIncoming := True;
                  when OBSTRUCTION =>
                     Put_Line("Obstruction detected...");
                  when others =>
                     if Integer'Value(car.speed'Image) < Integer'Value(world.curStreetSpeedLimit'Image) then
                        modifySpeed(1);
                     end if;
               end case;
            elsif Integer'Value(car.speed'Image) = 0 then
               Put_Line("Car turned a corner!");
               turnIncoming := False;
               carTurned;
            else
               modifySpeed(-1);
            end if;
            dischargeBattery;
         end if;

         if warnLowBattery then
            Put_Line("Warning:"& car.battery'Image &"% battery remaining");
         elsif endJourney and Integer'Value(car.speed'Image) = 0 then
            Put_Line("Car parked at destination!");
            endJourney := False;
            changeGear(PARKED);
         elsif car.gear /= PARKED then
            Put_Line("Battery:"& car.battery'Image &"%, speed:"& car.speed'Image);
         end if;
         delay 0.5;
      end loop;
   end Driving;
begin
   null;
end Main;
