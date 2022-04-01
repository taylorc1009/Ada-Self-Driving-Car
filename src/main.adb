with WorldPackage; use WorldPackage;
with Ada.Text_IO; use Ada.Text_IO;
with RandGen; use RandGen;

procedure Main is
   inputStr : String(1..2);
   inputLast : Natural := 1;
   turnIncoming : Boolean := False;
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
      elsif not turnIncoming then
         case generateScenario is
         when TURN =>
            turnIncoming := True;
         when OBSTRUCTION =>
            null;
         when others =>
            if Integer'Value(car.speed'Image) < Integer'Value(world.curStreetSpeedLimit'Image) then
              modifySpeed(1);
            end if;
         end case;
      end if;

      if warnLowBattery then
         Put_Line("Warning:"& car.battery'Image &"% battery remaining");
      else
         Put_Line("Battery:"& car.battery'Image &"%, speed:"& car.speed'Image);
      end if;

      dischargeBattery;
      delay 0.5;
   end loop;
   Put_Line("Battery: 0%");
end Main;
