----------------------------------------------------------------------------------
-- Company: USAFA
-- Engineer: Ryan Good
-- 
-- Create Date:    20:00:26 01/30/2014 
-- Design Name: 	 font_controller
-- Module Name:    atlys_lab_font_controller
-- Project Name: 	 font_controller
-- Target Devices: VGA monitors
-- Tool versions: N/A
-- Description: Displays various ASCII letters on the screen as desired by the
-- customer.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.NUMERIC_STD.ALL;

entity atlys_lab_font_controller is
    port (
             clk    : in  std_logic; -- 100 MHz
             reset  : in  std_logic;
             start  : in  std_logic;
             switch : in  std_logic_vector(7 downto 0);
             led    : out std_logic_vector(7 downto 0);
             tmds   : out std_logic_vector(3 downto 0);
             tmdsb  : out std_logic_vector(3 downto 0)
    );
end atlys_lab_font_controller;

architecture Good of atlys_lab_font_controller is

component vga_sync
	port (
		clk	: in std_logic;
		reset	: in std_logic;
		h_sync	: out std_logic;
		v_sync	: out std_logic;
		v_completed : out std_logic;
		blank	: out std_logic;
		row	: out unsigned(10 downto 0);
		column	: out unsigned(10 downto 0)
	);
end component;

component character_gen
port ( clk            : in std_logic;
       blank          : in std_logic;
       row            : in std_logic_vector(10 downto 0);
       column         : in std_logic_vector(10 downto 0);
       ascii_to_write : in std_logic_vector(7 downto 0);
       write_en       : in std_logic;
		 reset			 : in std_logic;
       r,g,b          : out std_logic_vector(7 downto 0)
     );
end component;

component font_rom
	port( clk: in std_logic;
			addr: in std_logic_vector(10 downto 0);
			data: out std_logic_vector(7 downto 0)
		 );
end component;

component button_pressed
	port(
		clk         : in std_logic;
      reset       : in std_logic;
		button_in	: in std_logic;
		button_out	: out std_logic
		);
end component;

    signal pixel_clk, serialize_clk, serialize_clk_n, blank_sig, blank_sig1, blank_sig2, enable_sig: std_logic;
	 signal h_sync_sig, v_sync_sig, v_completed_sig, h_sync_sig_1, h_sync_sig_2, v_sync_sig_1, 
			  v_sync_sig_2: std_logic;
	 signal red, green, blue : std_logic_vector (7 downto 0);
	 signal red_s, green_s, blue_s, clock_s : std_logic;
	 signal row_sig, column_sig : unsigned(10 downto 0);
begin

    -- Clock divider - creates pixel clock from 100MHz clock
    inst_DCM_pixel: DCM
    generic map(
                   CLKFX_MULTIPLY => 2,
                   CLKFX_DIVIDE => 8,
                   CLK_FEEDBACK => "1X"
               )
    port map(
                clkin => clk,
                rst => reset,
                clkfx => pixel_clk
            );

    -- Clock divider - creates HDMI serial output clock
    inst_DCM_serialize: DCM
    generic map(
                   CLKFX_MULTIPLY => 10, -- 5x speed of pixel clock
                   CLKFX_DIVIDE => 8,
                   CLK_FEEDBACK => "1X"
               )
    port map(
                clkin => clk,
                rst => reset,
                clkfx => serialize_clk,
                clkfx180 => serialize_clk_n
            );

inst_vga_sync: vga_sync
	port map(
		clk	=> pixel_clk,
		reset	=> reset,
		h_sync	=> h_sync_sig,
		v_sync	=> v_sync_sig,
		v_completed => v_completed_sig,
		blank	=> blank_sig,
		row	=> row_sig,
		column	=> column_sig
	);
	
inst_character_gen: character_gen
port map(
		 clk	=> pixel_clk,
       blank => blank_sig2,
       row => std_logic_vector(row_sig),
       column => std_logic_vector(column_sig),
       ascii_to_write => switch,
       write_en => enable_sig,
		 reset	=> reset,
       r => red,
		 g => green,
		 b => blue
     );
	  
button_pressed_init: button_pressed
port map(
		clk	=> pixel_clk,
      reset => reset,     
		button_in	=> start,
		button_out	=> enable_sig
	);
	  
--------------------------Let there be delays!----------------------------------

--blank flip flop one
process (pixel_clk) is
	begin
		if rising_edge(pixel_clk) then
			blank_sig1 <= blank_sig;
		end if;
end process;

--blank flip flop two
process (pixel_clk) is
	begin
		if rising_edge(pixel_clk) then
			blank_sig2 <= blank_sig1;
		end if;
end process;

--h sync flip flop one
process (pixel_clk) is
	begin
		if rising_edge(pixel_clk) then
			h_sync_sig_1 <= h_sync_sig;
		end if;
end process;

--h sync flip flop two
process (pixel_clk) is
	begin
		if rising_edge(pixel_clk) then
			h_sync_sig_2 <= h_sync_sig_1;
		end if;
end process;

--v sync flip flop one
process (pixel_clk) is
	begin
		if rising_edge(pixel_clk) then
			v_sync_sig_1 <= v_sync_sig;
		end if;
end process;

--v sync flip flop two
process (pixel_clk) is
	begin
		if rising_edge(pixel_clk) then
			v_sync_sig_2 <= v_sync_sig_1;
		end if;
end process;

-----------------------------------------------------------


    -- Convert VGA signals to HDMI (actually, DVID ... but close enough)
    inst_dvid: entity work.dvid
    port map(
                clk => serialize_clk,
                clk_n => serialize_clk_n,
                clk_pixel => pixel_clk,
                red_p => red,
                green_p => green,
                blue_p => blue,
                blank => blank_sig2,
                hsync => h_sync_sig_2,
                vsync => v_sync_sig_2,
                -- outputs to TMDS drivers
                red_s => red_s,
                green_s => green_s,
                blue_s => blue_s,
                clock_s => clock_s
            );

    -- Output the HDMI data on differential signalling pins
    OBUFDS_blue : OBUFDS port map
        ( O => TMDS(0), OB => TMDSB(0), I => blue_s );
    OBUFDS_red : OBUFDS port map
        ( O => TMDS(1), OB => TMDSB(1), I => green_s );
    OBUFDS_green : OBUFDS port map
        ( O => TMDS(2), OB => TMDSB(2), I => red_s );
    OBUFDS_clock : OBUFDS port map
        ( O => TMDS(3), OB => TMDSB(3), I => clock_s );

end Good;
