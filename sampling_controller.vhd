----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 01.12.2025 16:30:00
-- Design Name:
-- Module Name: sampling_controller - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description: Sampling controller for periodic temperature reading
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

entity sampling_controller is
    Port (
        clk             : in  STD_LOGIC;
        rst             : in  STD_LOGIC;
        clk_sampling    : in  STD_LOGIC;
        busy            : in  STD_LOGIC;
        trig            : out STD_LOGIC
    );
end sampling_controller;

architecture Behavioral of sampling_controller is

    -- 状态机类型定义
    type state_type is (
        state_idle,     -- 空闲等待，等待clk_sampling变高
        state_start,    -- 产生触发脉冲，等待busy变高
        state_wait      -- 等待读取完成，busy变低且clk_sampling变低
    );

    signal state, next_state : state_type;

begin

    -- ========================================================================
    -- 进程1: 同步状态寄存器
    -- ========================================================================
    SYNC_PROC: process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= state_idle;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- ========================================================================
    -- 进程2: Moore状态机输出逻辑 (基于当前状态)
    -- ========================================================================
    OUTPUT_DECODE: process (state)
    begin
        -- 默认值
        trig <= '0';

        case state is
            when state_idle =>
                trig <= '0';

            when state_start =>
                trig <= '1';    -- 产生触发脉冲

            when state_wait =>
                trig <= '0';

            when others =>
                trig <= '0';

        end case;
    end process;

    -- ========================================================================
    -- 进程3: 下一状态逻辑
    -- ========================================================================
    NEXT_STATE_DECODE: process (state, clk_sampling, busy)
    begin
        -- 默认保持当前状态
        next_state <= state;

        case state is
            when state_idle =>
                if clk_sampling = '1' then
                    next_state <= state_start;
                end if;

            when state_start =>
                if busy = '1' then
                    next_state <= state_wait;
                end if;

            when state_wait =>
                if busy = '0' and clk_sampling = '0' then
                    next_state <= state_idle;
                end if;

            when others =>
                next_state <= state_idle;

        end case;
    end process;

end Behavioral;
