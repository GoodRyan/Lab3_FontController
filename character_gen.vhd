----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:39:33 02/21/2014 
-- Design Name: 
-- Module Name:    character_gen - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity character_gen is
port ( clk            : in std_logic;
       blank          : in std_logic;
       row            : in std_logic_vector(10 downto 0);
       column         : in std_logic_vector(10 downto 0);
       ascii_to_write : in std_logic_vector(7 downto 0);
       write_en       : in std_logic;
		 reset			 : in std_logic;
       r,g,b          : out std_logic_vector(7 downto 0)
     );
end character_gen;

architecture Behavioral of character_gen is

component char_screen_buffer
	port(	clk        : in std_logic;
         we         : in std_logic;                     -- write enable
         address_a  : in std_logic_vector(11 downto 0); -- write address, primary port
         address_b  : in std_logic_vector(11 downto 0); -- dual read address
         data_in    : in std_logic_vector(7 downto 0);  -- data input
         data_out_a : out std_logic_vector(7 downto 0); -- primary data output
         data_out_b : out std_logic_vector(7 downto 0)  -- dual output port
		 );
end component;

component font_rom
	port( clk: in std_logic;
			addr: in std_logic_vector(10 downto 0);
			data: out std_logic_vector(7 downto 0)
		 );
end component;

signal data_out_b_sig : std_logic_vector(7 downto 0);
signal row_flip_flop	 : std_logic_vector(3 downto 0);
signal addr_sig		 : std_logic_vector(10 downto 0);
signal address_b_sig	 : std_logic_vector(13 downto 0);
signal data_sig		 : std_logic_vector(7 downto 0);
signal column_flip_flop_one, column_flip_flop_two : std_logic_vector(2 downto 0);
signal mux_out			 : std_logic;
signal count, count_next : unsigned(11 downto 0);

begin


--todo: write code that selects locations for address_b
char_screen_buffer_init: char_screen_buffer
  port map(
    clk => clk,
	 we => write_en,
	 address_a => std_logic_vector(count),
	 address_b => address_b_sig(11 downto 0),
	 data_in => ascii_to_write,
	 data_out_a => open,
	 data_out_b =>	data_out_b_sig
  );
  
font_rom_init: font_rom
	port map(
		clk => clk,
		addr => addr_sig,
		data => data_sig
	);
	
--f(row, column)
address_b_sig <= std_logic_vector(unsigned(row(10 downto 4))*80 + unsigned(column(10 downto 3)));

--row flip flop
process (clk) is
   begin
      if rising_edge(clk) then  
         row_flip_flop <= row(3 downto 0);
      end if;
end process;

addr_sig <= data_out_b_sig(6 downto 0) & row_flip_flop(3 downto 0);

--first column flip flop
process (clk) is
	begin
		if rising_edge(clk) then
			column_flip_flop_one <= column(2 downto 0);
		end if;
end process;

--second column flip flop
process (clk) is
	begin
		if rising_edge(clk) then
			column_flip_flop_two <= column_flip_flop_one;
		end if;
end process;

--8 to 1 mux
with column_flip_flop_two select mux_out <= data_sig(0) when "000",
														  data_sig(1) when "001",
														  data_sig(2) when "010",
														  data_sig(3) when "011",
														  data_sig(4) when "100",
														  data_sig(5) when "101",
														  data_sig(6) when "110",
														  data_sig(7) when "111";
														  
--output
process(blank, mux_out)
begin

r <= (others => '0');
g <= (others => '0');
b <= (others => '0');

if(blank = '0') then
	if(mux_out = '1') then
		r <= (others => '1');
	end if;
end if;
end process;

--counter
count_next <= (others => '0') when reset = '1' else count;

count <= count_next + 1 when write_en = '1' else count_next;
			

--create address signal

end Behavioral;

