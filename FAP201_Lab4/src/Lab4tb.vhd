library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lab04_tb is
end entity lab04_tb;

architecture sim of lab04_tb is
  constant CLK_PERIOD : time := 20 ns;
  signal clk          : STD_LOGIC := '0';
  signal i_sw_raw     : STD_LOGIC := '0';
  signal i_rst        : STD_LOGIC := '0';
  signal o_led        : STD_LOGIC;
  signal o_dbg_stable : STD_LOGIC;
begin
  clk <= not clk after CLK_PERIOD / 2;

  -- STABLE_CYCLES nhỏ (5) chỉ để mô phỏng nhanh
  DUT : entity work.lab04
    generic map (STABLE_CYCLES => 5)
    port map (
      clk          => clk,
      i_sw_raw     => i_sw_raw,
      i_rst        => i_rst,
      o_led        => o_led,
      o_dbg_stable => o_dbg_stable
    );

  stimulus : process
  begin
    -- T0. Reset
    i_rst <= '1';
    wait for 4 * CLK_PERIOD;
    i_rst <= '0';
    wait for 3 * CLK_PERIOD;
    assert o_led = '0' report "T0 FAILED: LED must reset to 0" severity error;
    assert o_dbg_stable = '0' report "T0 FAILED: stable switch must reset to 0" severity error;

    -- T1. Nhấn có nảy
    i_sw_raw <= '1'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '0'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '1'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '0'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '1';
    wait for 12 * CLK_PERIOD;
    assert o_dbg_stable = '1' report "T1 FAILED: press was not accepted" severity error;
    assert o_led = '0' report "T1 FAILED: press must not toggle LED" severity error;

    -- T2. Giữ nút lâu, không toggle thêm
    wait for 20 * CLK_PERIOD;
    assert o_led = '0' report "T2 FAILED: LED changed while pressed" severity error;

    -- T3. Nhả có nảy
    i_sw_raw <= '0'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '1'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '0'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '1'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '0';
    wait for 16 * CLK_PERIOD;
    assert o_dbg_stable = '0' report "T3 FAILED: release was not accepted" severity error;
    assert o_led = '1' report "T3 FAILED: first release must toggle LED ON" severity error;

    -- T4. Đứng yên ở trạng thái nhả
    wait for 20 * CLK_PERIOD;
    assert o_led = '1' report "T4 FAILED: LED changed without new release" severity error;

    -- T5. Nhấn/nhả lần 2
    i_sw_raw <= '1'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '0'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '1';
    wait for 12 * CLK_PERIOD;
    assert o_led = '1' report "T5 FAILED: press caused a toggle" severity error;

    i_sw_raw <= '0'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '1'; wait for 1 * CLK_PERIOD;
    i_sw_raw <= '0';
    wait for 16 * CLK_PERIOD;
    assert o_led = '0' report "T5 FAILED: second release must toggle LED OFF" severity error;

    -- T6. Reset lại
    i_rst <= '1';
    wait for 2 * CLK_PERIOD;
    i_rst <= '0';
    wait for 2 * CLK_PERIOD;
    assert o_led = '0' report "T6 FAILED: reset did not clear LED" severity error;

    report "LAB04: ALL SELF-CHECKING TESTS PASSED" severity note;
    wait;
  end process;
end architecture sim;