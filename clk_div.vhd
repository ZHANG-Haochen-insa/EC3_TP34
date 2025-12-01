library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_div is
    Port (
        clk_in      : in  STD_LOGIC;                    -- 100 MHz input clock
        rst         : in  STD_LOGIC;                    -- Reset signal
        clk_sampling: out STD_LOGIC;                    -- ~3 Hz output clock for sampling
        clk_display : out STD_LOGIC                     -- ~6 kHz output clock for display
    );
end clk_div;

architecture Behavioral of clk_div is
    -- Clock division constants
    -- For 3 Hz from 100 MHz: 100_000_000 / 3 = 33_333_333 (half period: 16_666_667)
    constant SAMPLING_DIV : integer := 16_666_667;

    -- For 6 kHz from 100 MHz: 100_000_000 / 6000 = 16_667 (half period: 8_333)
    constant DISPLAY_DIV  : integer := 8_333;

    -- Counter signals
    signal cnt_sampling : integer range 0 to SAMPLING_DIV := 0;
    signal cnt_display  : integer range 0 to DISPLAY_DIV := 0;

    -- Internal clock signals
    signal clk_sampling_i : STD_LOGIC := '0';
    signal clk_display_i  : STD_LOGIC := '0';

begin
    -- Output assignment
    clk_sampling <= clk_sampling_i;
    clk_display  <= clk_display_i;

    -- Process for generating clk_sampling (~3 Hz)
    process(clk_in, rst)
    begin
        if rst = '1' then
            cnt_sampling <= 0;
            clk_sampling_i <= '0';
        elsif rising_edge(clk_in) then
            if cnt_sampling = SAMPLING_DIV then
                cnt_sampling <= 0;
                clk_sampling_i <= not clk_sampling_i;  -- Toggle clock
            else
                cnt_sampling <= cnt_sampling + 1;
            end if;
        end if;
    end process;

    -- Process for generating clk_display (~6 kHz)
    process(clk_in, rst)
    begin
        if rst = '1' then
            cnt_display <= 0;
            clk_display_i <= '0';
        elsif rising_edge(clk_in) then
            if cnt_display = DISPLAY_DIV then
                cnt_display <= 0;
                clk_display_i <= not clk_display_i;  -- Toggle clock
            else
                cnt_display <= cnt_display + 1;
            end if;
        end if;
    end process;

end Behavioral;
