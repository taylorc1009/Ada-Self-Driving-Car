with World; use World;
with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   while car.battery > 0 loop
      Put_Line("Battery: "& car.battery'Image &"%");
      dischargeBattery;
      delay 0.5;
   end loop;
   Put_Line("Battery: 0%");
end Main;
