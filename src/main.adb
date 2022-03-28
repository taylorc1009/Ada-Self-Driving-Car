with World; use World;
with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
   engineStartStr : String(1..2);
   engineStartLast : Natural := 1;
begin
   while car.battery > 0 loop
      if car.engineOn = False then
         Put("Press ENTER to start the car");
         Get_Line(engineStartStr, engineStartLast);
         engineSwitch;
      end if;

      if car.gear = PARKED then
         Put("Press ENTER to put the car into drive");
         Get_Line(engineStartStr, engineStartLast);
         changeGear(DRIVE);
      end if;

      if warnLowBattery then
         Put_Line("Warning:"& car.battery'Image &"% battery remaining");
      else
         Put_Line("Battery:"& car.battery'Image &"%");
      end if;

      dischargeBattery;
      delay 0.5;
   end loop;
   Put_Line("Battery: 0%");
end Main;
