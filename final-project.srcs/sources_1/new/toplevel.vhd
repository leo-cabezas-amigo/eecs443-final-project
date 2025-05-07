----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/01/2025 01:09:19 PM
-- Design Name: 
-- Module Name: toplevel - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.NUMERIC_STD.ALL;

entity IntersectionController is
    generic(
        clock_rate:     natural := 100E6;
        delay_seconds:  natural := 3
    );
    port(
        clk:    in std_logic; -- 100 MHz clock
        reset:  in std_logic; -- reset signal
        car_ns: in std_logic;
        car_ew: in std_logic;
        lights: out std_logic_vector(5 downto 0) -- LED output
    );
end IntersectionController;

architecture Behavioral of IntersectionController is
    type state_type is (GNS, YNS, STOP_ALL, YEW, GEW);
    signal curr_state, next_state:  state_type := GNS;
    signal curr_lights, next_lights: std_logic_vector(5 downto 0) := "100001";
    
    constant COUNTER_MAX:   unsigned(31 downto 0) := to_unsigned(delay_seconds * clock_rate, 32);
    signal counter: unsigned(31 downto 0) := (others => '0'); -- 32 bits for counting up to 2^32 - 1 if needed
begin
    UPDATE_STATE: process (clk, reset)
    begin
        if (reset = '1') then
            curr_state <= GNS;
        elsif rising_edge(clk) then
            if (counter = COUNTER_MAX) then
                curr_state  <= next_state;
                curr_lights <= next_lights;
                counter <= (others => '0');  -- Reset counter
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    MEALY_FSM: process (car_ns, car_ew)
    begin
        case curr_state is
            when GNS =>
                if (car_ew = '1' and car_ns = '0') then
                    next_state <= YNS;
                    next_lights <= "010001";
                else 
                    next_state <= GNS;
                    next_lights <= "100001";
                end if;
            when YNS =>
                if (car_ew = '0') then
                    next_state <= GNS;
                    next_lights <= "100001";
                else
                    next_state <= STOP_ALL;
                    next_lights <= "001001";
                end if;
            when STOP_ALL =>
                if (car_ew = '0') then
                    next_state <= YNS;
                    next_lights <= "010001";
                else
                    next_state <= YEW;
                    next_lights <= "001010";
                end if;
            when YEW =>
                if (car_ew = '0') then
                    next_state <= STOP_ALL;
                    next_lights <= "001001";
                else
                    next_state <= GEW;
                    next_lights <= "001100";
                end if;
            when GEW =>
                if (car_ew = '0' and car_ns = '1') then
                    next_state <= YEW;
                    next_lights <= "001010";
                else
                    next_state <= GEW;
                    next_lights <= "001100";
                end if;
        end case;
    end process;
    
    lights <= curr_lights;
    
end Behavioral;
