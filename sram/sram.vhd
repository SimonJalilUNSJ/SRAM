library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram is 
	generic(
		direc	: integer := 3;
		bits	: integer := 4
	);
	port(
		i_clk		:in std_logic;										
		i_dir		:in std_logic_vector(direc-1 downto 0);
		i_oe_low	:in std_logic;
		i_we_low :in std_logic;
		i_ce_low :in std_logic;
		i_dat		:in std_logic_vector(bits-1 downto 0);
		o_dat		:out std_logic_vector(bits-1 downto 0)
	);
end entity sram;

architecture behav of sram is
	type memoria is array(0 to (2**direc)-1) of std_logic_vector(bits-1 downto 0);
	signal ram:memoria;
begin 
	clk_sram:process(i_clk)  
		begin
			if(rising_edge(i_clk)) then
				if(i_we_low = '0' and i_ce_low = '0') then 
					ram(to_integer(unsigned(i_dir))) <= i_dat;
				elsif(i_oe_low = '0' and i_ce_low = '0') then
					o_dat <= ram(to_integer(unsigned(i_dir)));
				else 
					o_dat <= (others => 'Z');
				end if;
			end if;
		end process;
end architecture behav;
	