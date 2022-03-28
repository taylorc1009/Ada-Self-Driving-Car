with World; use World;
with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   while car.battery > 0 loop
      Put_Line("Battery: "& car.battery'Image &"%");
      dischargeBattery;
   end loop;
end Main;
