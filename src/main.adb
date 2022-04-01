with WorldPackage; use WorldPackage;
with Ada.Text_IO; use Ada.Text_IO;
with RandGen; use RandGen;

procedure Main is
   inputStr : String(1..2);
   inputLast : Natural := 1;
   turnIncoming : Boolean := False;
   endJourney : Boolean := False;
begin
   while car.battery > 0 loop
      if car.engineOn = False then
         Put("Press ENTER to start the car");
         Get_Line(inputStr, inputLast);
         engineSwitch;
      end if;

      if car.gear = PARKED then
         Put_Line("Enter a number to put the car into: 1 = drive, 2 = reverse, 3 = diagnostics mode");
         <<select_gear>>
         Get_Line(inputStr, inputLast);
         case inputStr(1) is
            when '1' =>
               changeGear(DRIVE);
            when '2' =>
               changeGear(REVERSING);

            when others =>
               Put_Line("(!) error: invalid entry, please enter a number within the given range");
               goto select_gear;
         end case;
         Put_Line("Gear changed to: "& car.gear'Image);
         initialiseRoute;
      else
         if not turnIncoming and not endJourney then
            case generateScenario is
               when ARRIVED =>
                  Put_Line("Car arrived at destination! Preparing to park...");
                  endJourney := True;
               when TURN =>
                  Put_Line("Upcoming turn: slowing dow to prepare for the turn...");
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
      end if;

      if warnLowBattery then
         Put_Line("Warning:"& car.battery'Image &"% battery remaining");
      elsif endJourney and Integer'Value(car.speed'Image) = 0 then
         Put_Line("Car parked at destination!");
         endJourney := False;
         changeGear(PARKED);
      else
         Put_Line("Battery:"& car.battery'Image &"%, speed:"& car.speed'Image);
      end if;

      dischargeBattery;
      delay 0.5;
   end loop;
   Put_Line("Battery: 0%");
end Main;
