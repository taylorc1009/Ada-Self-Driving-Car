with WorldPackage; use WorldPackage;
with Ada.Text_IO; use Ada.Text_IO;
with RandGen; use RandGen;

procedure Main is
   inputStr : String(1..2);
   inputLast : Natural := 1;
   task Controller is
      pragma Priority(10);
   end Controller;
   task Driving;
   task DiagnosticsMode;

   task body Controller is
   begin
      loop
         Put_Line("At any time, select an option for the car to do:");
         Put_Line(" - 0 = display the car's conditions");
         Put_Line(" - 1 = toggle engine (car will charge while off)");
         Put_Line(" - 2 = change gear");
         Put_Line(" - 3 = toggle diagnostics mode");
         Put_Line(" - anything else = exit car");
         Get_Line(inputStr, inputLast);

         case inputStr(1) is
            when '0' =>
               Put_Line("Car's current condition:");
               Put_Line(" - Engine: "& (if car.engineOn then "ON" else "OFF"));
               Put_Line(" - Gear: "& car.gear'Image);
               Put_Line(" - Diagnostics Mode: "& (if car.diagnosticsOn then "ON" else "OFF"));
            when '1' =>
               engineSwitch;
               Put_Line("Engine: "& (if car.engineOn then "ON" else "OFF"));
            when '2' =>
               Put_Line("Enter a number to put the car into:");
               Put_Line(" - 0 = drive");
               Put_Line(" - 1 = reverse");
               Put_Line(" - 2 = parked");
               <<select_gear>>
               Get_Line(inputStr, inputLast);
               case inputStr(1) is
                  when '0' =>
                     changeGear(DRIVE);
                     initialiseRoute;
                  when '1' =>
                     changeGear(REVERSING);
                  when '2' =>
                     changeGear(PARKED);
                  when others =>
                     Put_Line("(!) error: invalid entry, please enter a number within the given range");
                     goto select_gear;
               end case;
               Put_Line("Gear: "& car.gear'Image);
            when '3' =>
               diagnosticsSwitch;
               Put_Line("Diagnostics mode enabled; this takes 10 seconds");
            when others =>
               if car.speed /= 0 then
                  Put_Line("You cannot exit the car when it is in motion");
               elsif car.engineOn then
                  Put_Line("Please turn the engine off before exiting the car");
               else
                  abort Driving;
                  abort DiagnosticsMode;
                  exit;
               end if;
         end case;
         Put_Line("");
      end loop;
   end Controller;

   task body Driving is
   begin
      loop
         if car.engineOn and car.gear /= PARKED then
            if not (world.turnIncoming or world.destinationReached or car.forceNeedsCharged or car.parkRequested or car.gear = REVERSING) then
               case generateScenario is
                  when ARRIVED =>
                     world.destinationReached := True;
                     Put_Line("Car arrived at destination! Preparing to park...");
                  when TURN =>
                     carTurn;
                     Put_Line("Upcoming turn: slowing down to prepare for the turn...");
                  when OBSTRUCTION =>
                     Put_Line("Obstruction detected! Performing EMERGENCY STOP");
                     emergencyStop;
                     Put_Line("Reversing to divert obstruction...");
                     divertObstruction;
                  when others =>
                     modifySpeed(1);
               end case;
            elsif Integer'Value(car.speed'Image) = 0 and not world.obstructionPresent then -- car is stopped in this scenario
               if car.forceNeedsCharged and car.engineOn then
                  changeGear(PARKED);
                  engineSwitch;
                  Put_Line("Car powered off, please charge the car...");
               elsif car.parkRequested then
                  changeGear(PARKED);
                  Put_Line("Park request complete!");
               elsif world.turnIncoming then
                  Put_Line("Car turned a corner!");
                  carTurn;
               end if;
            elsif car.speed = MilesPerHour'First and world.obstructionPresent then
               Put_Line("Car now has enough space to avoid obstruction; continuing on current route...");
               divertObstruction;
            else
               modifySpeed(-1);
            end if;

            checkNeedsChargeEnforce;
            case carConditionCheck is
               when LOW_BATTERY =>
                  Put_Line("Warning:"& car.battery'Image &"% battery remaining");
                  if car.forceNeedsCharged then
                     Put_Line("Car predicted that there is insufficient battery remaining for the rest of the journey; slowing down and pulling over...");
                  end if;
               when HAS_ARRIVED =>
                  arriveAtDestination;
                  Put_Line("Car parked at destination!");
               when GENERAL =>
                  Put_Line("Battery:"& car.battery'Image &"%, speed:"& car.speed'Image);
               when others =>
                  null;
            end case;
            dischargeBattery;
         end if;
         delay 0.5;
      end loop;
   end Driving;

   task body DiagnosticsMode is
   begin
      loop
         -- ideally, the tread would wait until diagnostics is enabled instead of looping over an if statement to check this, but I'm unsure how to do this in SPARK
         if car.diagnosticsOn then
            delay 10.0;
            diagnosticsSwitch;
            Put_Line("Diagnostics complete!");
         end if;
      end loop;
   end DiagnosticsMode;
begin
   null;
end Main;
