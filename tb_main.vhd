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
    signal clk : std_logic;
    signal rst : std_logic;
    signal LED : std_logic_vector(15 downto 0);
    signal JA  : std_logic_vector(1 downto 0);
    signal sda : std_logic := 'H';  -- 初始化为高阻态，带上拉
    signal scl : std_logic := 'H';  -- 初始化为高阻态，带上拉

    -- 时钟参数
    constant TbPeriod : time := 10 ns;  -- 100 MHz时钟周期
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

    -- 测试数据：25.1°C = 0x0C88
    -- 寄存器0 (MSB): 0x0C = 00001100
    -- 寄存器1 (LSB): 0x88 = 10001000
    constant TEMP_MSB : std_logic_vector(7 downto 0) := "00001100";
    constant TEMP_LSB : std_logic_vector(7 downto 0) := "10001000";

    -- I2C从设备地址
    constant SENSOR_ADDR : std_logic_vector(6 downto 0) := "1001011";  -- 0x4B

    -- I2C总线模拟信号
    signal i2c_state : integer := 0;  -- I2C从设备状态机

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
    -- I2C从设备模拟（简化版）
    -- 功能：模拟ADT7420温度传感器的I2C响应
    --
    -- 注意：这是一个高度简化的I2C从设备模拟
    -- 在实际仿真中，建议使用以下方法之一：
    -- 1. 使用专业的I2C从设备BFM（Bus Functional Model）
    -- 2. 使用真实的ADT7420传感器VHDL模型（如果可用）
    -- 3. 直接观察I2C总线波形，手动验证协议正确性
    --
    -- 本testbench主要用于验证：
    -- - 系统时钟分频是否正确
    -- - 各模块连接是否正确
    -- - 状态机是否正常工作
    -- ========================================================================
    i2c_slave_sim : process
    begin
        -- 初始化：I2C总线空闲时为高电平（上拉）
        sda <= 'H';  -- 弱上拉到高电平

        -- 简化模拟：直接通过弱驱动模拟上拉电阻
        -- 在实际的I2C通信中，从设备会在适当时机拉低SDA
        -- 这里为了简化，我们不完全模拟I2C协议

        report "注意：I2C从设备模拟已简化" severity note;
        report "建议通过波形查看I2C通信过程" severity note;
        report "预期温度值：0x0C88 (25.1°C)" severity note;

        -- 保持I2C总线空闲
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
        report "复位释放，系统开始运行" severity note;
        wait for 1 us;

        -- 观察系统运行
        -- 系统应该自动每约333ms（3Hz）读取一次温度
        report "等待第一次温度读取..." severity note;
        wait for 2 ms;

        report "观察LED输出：" & integer'image(to_integer(unsigned(LED))) severity note;

        -- 等待第二次读取
        report "等待第二次温度读取..." severity note;
        wait for 2 ms;

        report "观察LED输出：" & integer'image(to_integer(unsigned(LED))) severity note;

        -- 测试复位功能
        report "测试复位功能" severity note;
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 2 ms;

        -- 结束仿真
        report "仿真完成" severity note;
        TbSimEnded <= '1';
        wait;
    end process;

    -- ========================================================================
    -- 监视进程：输出关键信号变化
    -- ========================================================================
    monitor : process
    begin
        wait until LED'event;
        if LED /= x"0000" then
            report "LED变化 (十进制: " & integer'image(to_integer(unsigned(LED))) & ")"
                   severity note;
        end if;
    end process;

end tb;

-- ============================================================================
-- 配置
-- ============================================================================
configuration cfg_tb_main of tb_main is
    for tb
    end for;
end cfg_tb_main;
