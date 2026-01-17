## Clock Signal (100 MHz Sistem Saati)
set_property PACKAGE_PIN W5 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK]

## Pmod Header JA (Port A)
## LCD Bağlantı Sıralaması Aşağıdaki Gibidir:

## JA Pin 1 (Üst sıra sol) -> RS
set_property PACKAGE_PIN J1 [get_ports RS]
set_property IOSTANDARD LVCMOS33 [get_ports RS]

## JA Pin 2 (Üst sıra) -> Enable (E)
set_property PACKAGE_PIN L2 [get_ports E]
set_property IOSTANDARD LVCMOS33 [get_ports E]

## JA Pin 3 (Üst sıra) -> Data 4 (D[4])
set_property PACKAGE_PIN J2 [get_ports {D[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D[4]}]

## JA Pin 4 (Üst sıra sağ) -> Data 5 (D[5])
set_property PACKAGE_PIN G2 [get_ports {D[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D[5]}]

## JA Pin 7 (Alt sıra sol) -> Data 6 (D[6])
set_property PACKAGE_PIN H1 [get_ports {D[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D[6]}]

## JA Pin 8 (Alt sıra) -> Data 7 (D[7])
set_property PACKAGE_PIN K2 [get_ports {D[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {D[7]}]

## Not: LCD'nin RW bacağını GND'ye bağlamayı unutma!
## Not: LCD'nin V0 (Kontrast) bacağına potansiyometre bağlaman gerekebilir.