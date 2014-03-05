Lab3_FontController
===================

Introduction
============

The purpose of this lab was to enable the user to display ASCII characters as they desired. The final goal, which I was unable to accomplish, was to allow the user to modify the characters using a game controller.


Implementation
==============

The main work of this lab occurs in the character_gen.vhd file. The purpose of this code is to connect the screen buffer to the font rom appropriately, along with other signals provided by the vga sync. These connections allow for the proper output of rgb signals as desired by the user.

An interesting problem that had to be solved in writing this code was the offset required to ensure timing occurred appropriately. If these offsets were not inserted, the letters would appear in the incorrect location on the screen. While these incorrect printings were minor, they summed to create a major discrepency in the final product. In order to solve this offset issues, some of the signals were put through an additional flip flop to create a one clock cycle delay. These signals included column, which required two flip flops, row, blank, h sync, and v sync. After these delays were inserted, the printing issues were solved. Some example flip flops are displayed below.

```VHDL
--h sync flip flop one
process (pixel_clk) is
  begin
    if rising_edge(pixel_clk) then
      h_sync_sig_1 <= h_sync_sig;
    end if;
end process;

---h sync flip flop two
process (pixel_clk) is
  begin
    if rising_edge(pixel_clk) then
      h_sync_sig_2 <= h_sync_sig_1;
    end if;
end process;
```

This block of code delays h sync sig by two clock cycles, enabling it to be appropriately used as a signal input to other modules in the design.

Testing
=======

One important error I ran into while testing my code was that the screen would turn entirely red, when only the portions appropriate for showing the ASCII character 'A' should have been turning red. The code that was causing my error is shown below.

```VHDL
 --output

 process(blank, mux_out)

 begin


 if(blank = '0') then

 	if(mux_out = '1') then

	r <= "11111111";

	r <= (others => '1');

 	end if;

 end if;

 end process;

```

The problem with this code was that it did not contain a base case. This resulted in the screen being permanently red in areas where it should have been turning black when appropriate. Below is the code with the appropriate base case.

```VHDL 
--output

 process(blank, mux_out)

 begin



r <= (others => '0');

g <= (others => '0');

b <= (others => '0');



 if(blank = '0') then

 	if(mux_out = '1') then

  	r <= "11111111";

		r <= (others => '1');

 	end if;

 end if;

 end process;
```

The base case for rgb fixed the issue, and enabled the appropriate areas of the screen to remain black. 

Conclusion
==========

This lab showed me the importance of timing when dealing with monitor displays. Having the slightest timing issue would result in an incorrect display, and some challenging debugging. It also showed me how important it is to ensure every component is interfaced correctly, as incorrect interfacing is difficult to debug. The only thing I would recommend changing to this lab is providing more guidance on interfacing with the game pad, as this is a large leap in VHDL understanding.
