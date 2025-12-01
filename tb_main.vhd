-- ============================================================================
-- Testbench for main
-- 功能：测试顶层模块，包含完整的温度读取系统
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_main is
end tb_main;

architecture tb of tb_main is

    -- ========================================================================
    -- 被测试组件声明
    -- ========================================================================
    component main
        port (
            clk : in    std_logic;
            rst : in    std_logic;
            LED : out   std_logic_vector(15 downto 0);
            JA  : out   std_logic_vector(1 downto 0);
            sda : inout std_logic;
            scl : inout std_logic
        );
    end component;

    -- ========================================================================
    -- 测试信号定义
    -- ========================================================================
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal LED : std_logic_vector(15 downto 0);
    signal JA  : std_logic_vector(1 downto 0);
    signal sda : std_logic;
    signal scl : std_logic;

    -- 时钟参数
    constant TbPeriod : time := 10 ns;  -- 100 MHz时钟周期
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

    -- 测试温度数据：25.1°C = 0x0C88
    constant TEMP_MSB : std_logic_vector(7 downto 0) := "00001100";  -- 0x0C
    constant TEMP_LSB : std_logic_vector(7 downto 0) := "10001000";  -- 0x88

    -- I2C从设备模拟信号
    signal sda_slave : std_logic := 'Z';

begin

    -- ========================================================================
    -- 被测试单元实例化
    -- ========================================================================
    dut : main
    port map (
        clk => clk,
        rst => rst,
        LED => LED,
        JA  => JA,
        sda => sda,
        scl => scl
    );

    -- ========================================================================
    -- 时钟生成
    -- ========================================================================
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    -- ========================================================================
    -- I2C总线上拉和从设备驱动
    -- ========================================================================
    sda <= 'H' when sda_slave = 'Z' else sda_slave;
    scl <= 'H';  -- SCL只有上拉

    -- ========================================================================
    -- I2C从设备模拟（ADT7420温度传感器）
    -- ========================================================================
    i2c_slave : process
        variable bit_index : integer;
        variable addr_byte : std_logic_vector(7 downto 0);
        variable reg_addr : std_logic_vector(7 downto 0);
    begin
        sda_slave <= 'Z';
        wait for 300 ns;

        while TbSimEnded = '0' loop
            -- 等待START条件：SCL为高时，SDA下降沿
            wait until (scl = '1' or scl = 'H') and sda = '0';
            wait for 500 ns;

            -- 接收地址字节（7位地址 + 1位R/W）
            addr_byte := (others => '0');
            for i in 7 downto 0 loop
                wait until scl = '1' or scl = 'H';
                addr_byte(i) := sda;
                wait until scl = '0';
            end loop;

            -- 发送ACK
            sda_slave <= '0';
            wait until scl = '1' or scl = 'H';
            wait until scl = '0';
            sda_slave <= 'Z';

            -- 如果是写操作（R/W=0），接收寄存器地址
            if addr_byte(0) = '0' then
                reg_addr := (others => '0');
                for i in 7 downto 0 loop
                    wait until scl = '1' or scl = 'H';
                    reg_addr(i) := sda;
                    wait until scl = '0';
                end loop;

                -- 发送ACK
                sda_slave <= '0';
                wait until scl = '1' or scl = 'H';
                wait until scl = '0';
                sda_slave <= 'Z';

                -- 等待重复START或STOP
                wait for 1 us;

                -- 检查是否有重复START（读操作）
                if (scl = '1' or scl = 'H') and sda = '0' then
                    wait for 500 ns;

                    -- 接收地址字节（读操作，R/W=1）
                    addr_byte := (others => '0');
                    for i in 7 downto 0 loop
                        wait until scl = '1' or scl = 'H';
                        addr_byte(i) := sda;
                        wait until scl = '0';
                    end loop;

                    -- 发送ACK
                    sda_slave <= '0';
                    wait until scl = '1' or scl = 'H';
                    wait until scl = '0';
                    sda_slave <= 'Z';

                    -- 发送MSB数据
                    for i in 7 downto 0 loop
                        wait until scl = '0';
                        sda_slave <= TEMP_MSB(i);
                        wait until scl = '1' or scl = 'H';
                    end loop;
                    wait until scl = '0';
                    sda_slave <= 'Z';

                    -- 接收主设备ACK
                    wait until scl = '1' or scl = 'H';
                    wait until scl = '0';

                    -- 发送LSB数据
                    for i in 7 downto 0 loop
                        wait until scl = '0';
                        sda_slave <= TEMP_LSB(i);
                        wait until scl = '1' or scl = 'H';
                    end loop;
                    wait until scl = '0';
                    sda_slave <= 'Z';

                    -- 接收主设备NACK
                    wait until scl = '1' or scl = 'H';
                    wait until scl = '0';
                end if;
            end if;

            -- 等待STOP条件或超时
            wait for 2 us;
        end loop;

        wait;
    end process;

    -- ========================================================================
    -- 激励信号生成
    -- ========================================================================
    stimuli : process
    begin
        -- 初始化
        rst <= '1';
        wait for 200 ns;

        -- 释放复位
        rst <= '0';

        -- 等待第一次温度读取完成
        -- 系统会在约333ms时触发第一次读取（3Hz），但为了加快仿真，我们等待足够时间
        wait for 500 us;

        -- 等待第二次读取
        wait for 500 us;

        -- 测试复位功能
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 500 us;

        -- 结束仿真
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- ============================================================================
-- 配置
-- ============================================================================
configuration cfg_tb_main of tb_main is
    for tb
    end for;
end cfg_tb_main;
