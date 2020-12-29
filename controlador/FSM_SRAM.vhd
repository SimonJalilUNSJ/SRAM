library ieee;
use ieee.std_logic_1164.all;

entity FSM_SRAM is 
	port(
		r_w			:in std_logic;		--Entrada de seleccion lectura=0/escritura=1
		clk 			:in std_logic;		--Entrada de clock.
		reset_low 	:in std_logic;		--Entrada de reset activo en bajo.
		ce_low		:out std_logic;	--Habilitacion de chip
		we_low 		:out std_logic;	--Habilitacion de escritura
		oe_low 		:out std_logic;	--Habilitacion de salida
		din			:out std_logic;	--Datos de entrada
		dout			:out std_logic		--Datos de salida
	);
end entity FSM_SRAM;

architecture behav of FSM_SRAM is
	
	--Declaro estados de la FSM.
	type FSM_states is (idle, write1, write2, write3, write4, read1, read2, read3, read4, read5, read6);
	signal current_state, next_state :FSM_states;
	
	--Establezco estilo de codificacion.
	attribute syn_encoding :string;
	attribute syn_encoding of FSM_states :type is "one hot";
	
	--Constantes para escritura.
	constant tsa 	:integer := 1;				--Address setup time.
	constant thzwe :integer := 450000;		--/WE LOW to High-Z Output
	constant tsd 	:integer := 450000;		--Data Setup to Write End
	constant tlzwe :integer := 150000;		--/WE HIGH to Low-Z Output
	constant thd 	:integer := 1;				--Data Hold from Write End;
	
	--Constantes para lectura.
	constant taa 	:integer := 1000000;		--Address Access Time.
	constant tdoe	:integer := 400000;		--/OE Access Time
	constant tlzoe	:integer := 1;				--/OE to Low-Z Output
	constant trc 	:integer := 1000000;		--Read Cycle Time
	constant thzce :integer := 400000;		--/CE to High-Z Output
	constant toha	:integer := 125000;		--Output Hold Time.
	constant thzoe :integer := 400000;		--/OE to High-Z Output
	
	signal cont 	:integer := 0; 			--Señal contador.
	
begin 
	cs_pr: process(clk,reset_low)
		begin 
			if (reset_low = '0') then 
				current_state <= idle;
			elsif(rising_edge(clk)) then
				current_state <= next_state;
			end if;
		end process;
		
	nx_pr: process(current_state)
		begin 
			case current_state is 
				when idle => 
					if (r_w = '0') then 
						next_state <= read1;
					else 
						next_state <= write1;
					end if;
				
				when read1 => 	
					if (cont < (taa-tdoe)) then 
						cont <= cont + 1;
						next_state <= read1;
					else 
						cont <= 0;
						next_state <= read2;
					end if;
			
				when read2 => 
					if (cont < tlzoe) then 
						cont <= cont + 1;
						next_state <= read2;
					else 
						cont <= 0;
						next_state <= read3;
					end if;
				
				when read3 => 
					if (cont < (tdoe - tlzoe)) then 
						cont <= cont + 1;
						next_state <= read3;
					else 
						cont <= 0;
						next_state <= read3;
					end if;
				
				when read4 => 
					if (cont < (trc - taa - thzce - toha)) then 
						cont <= cont + 1;
						next_state <= read4;
					else 
						cont <= 0;
						next_state <= read5;
					end if;
				
				when read5 => 
					if(cont < thzce - thzoe)then
						cont <= cont + 1;
						next_state <= read5;
					else 
						cont <= 0;
						next_state <= read6;
					end if;
				
				when read6 => 
					if(cont < thzoe)then
						cont <= cont + 1;
						next_state <= read6;
					else 
						cont <= 0;
						next_state <= idle;
					end if;
					
				when write1 => 
					if (cont < tsa) then 
						cont <= cont + 1; 
						next_state <= write1;
					else 
						cont <= 0;
						next_state <= write2;
					end if;
					
				when write2 => 
					if(cont < thzwe) then 
						cont <= cont + 1;
						next_state <= write2;
					else
						cont <= 0;
						next_state <= write3;
					end if;
					
				when write3 => 
					if(cont < tsd)then
						cont <= cont + 1;
						next_state <= write3;
					else 
						cont <= 0;
						next_state <= write4;
					end if;
				
				when write4 => 
					if(cont < (tlzwe - thd))then
						cont <= cont + 1;
						next_state <= write4;
					else 
						cont <= 0;
						next_state <= idle;
					end if;
				
				when others => 
					next_state <= idle;
				end case;
		end process;
						
	moore_pr: process(current_state)
		begin	
			--Valores por default de salida.
			ce_low <= '1';
			we_low <= '1';
			oe_low <= '1';
			din <= '0';
			dout <= '0';
			case current_state is
				when idle => null;
				when 	read1 => 
					ce_low <= '1';
					dout <= 'Z';
				when read2 => 
					ce_low <= '0';
					oe_low <= '0';
					dout <= 'Z';
				when read3 => 
					oe_low <= '0';
					we_low <= '0';
					dout <= '1';
				when read4 => 
					oe_low <= '0';
					we_low <= '0';
					dout <= '1';
				when read5 => 
					oe_low <= '0';
					dout <= '1';
				when read6 => 
					dout <= '1';
				when others => null;
			end case;
		end process;
end architecture behav;