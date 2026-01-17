library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- LCD Modülü Port Tanımlamaları
entity LCD_16x2 is
  Port (CLK: in std_logic;                     -- FPGA'den gelen ana saat sinyali (100 MHz)
        RS : out std_logic;                    -- Register Select: 0=Komut, 1=Veri
        E  : out std_logic;                    -- Enable: LCD'ye veriyi okuması için tetik sinyali
        D  : out std_logic_vector (7 downto 4) -- Data Bus: 4-bit veri yolu (Sadece D7-D4 kullanılır)
        );
end LCD_16x2;

architecture Behavioral of LCD_16x2 is
    
    -- Durum Makinesi (State Machine) Durumları:
    -- power_up: Açılış beklemesi
    -- init_seq: LCD'yi 4-bit moduna hazırlama ritüeli
    -- send_func_set: LCD ayarları (2 satır, 5x8 font vb.)
    -- send_display: Ekran aç/kapa
    -- send_clear: Ekranı temizle
    -- line1/line2: Yazı yazma aşamaları
    type CONTROL is (power_up, init_seq_1, init_seq_2, init_seq_3, init_seq_4, send_func_set, send_display_off, send_display_on, send_clear, send_entry_mode, line1, ch_line, line2, finish); 
    
    SIGNAL    state      : CONTROL;            -- Mevcut durumu tutan sinyal
    CONSTANT  freq       : INTEGER := 100;     -- Sistem saati frekansı (MHz cinsinden). Zamanlama hesapları için kullanılır.
    SIGNAL    ptr        : natural range 0 to 16 := 0; -- Harf dizisi içindeki sırayı takip eden işaretçi (Pointer)
    SIGNAL    row        : STD_LOGIC := '1';   -- Satır takibi (Şu an kullanılmıyor ama ileride lazım olabilir)
    SIGNAL    Data       : std_logic_vector (3 downto 0); -- Gönderilecek verinin geçici tutulduğu sinyal
    
    -- Harf tablosu için dizi tanımı (16 karakterlik)
    type CHARACTER_STRING is array (0 to 15) of std_logic_vector(7 downto 0);
    
    -- 1. Satırda yazacak metin: "SAKARYA UNIV.   " (ASCII kodları)
    constant line1_data : CHARACTER_STRING := (
        x"53", x"41", x"4B", x"41", x"52", x"59", x"41", x"20", -- SAKARYA_
        x"55", x"4E", x"49", x"56", x"2E", x"20", x"20", x"20"  -- UNIV.
    );

    -- 2. Satırda yazacak metin: "MUHENDISLIK     " (ASCII kodları)
    constant line2_data : CHARACTER_STRING := (
        x"4D", x"55", x"48", x"45", x"4E", x"44", x"49", x"53", -- MUHENDIS
        x"4C", x"49", x"4B", x"20", x"20", x"20", x"20", x"20"  -- LIK
    );

begin
    process(CLK)
        variable    clk_count : integer := 0; -- Zamanlama gecikmeleri için sayaç
    begin
        if rising_edge(CLK) then -- Her saat darbesinde (Rising Edge) çalışır
        
            case state is 
                
                -- [DURUM 1] Güç Açılış Beklemesi
                -- LCD'nin voltajı otursun diye 50ms beklenir.
                when power_up =>
                    if (clk_count < (5000*freq)) then -- 50 ms bekle
                        clk_count := clk_count + 1;
                        state <= power_up;
                    else
                        clk_count := 0;
                        RS <= '0'; -- Komut moduna geç
                        state <= init_seq_1;                  
                    end if;
                        
                -- [DURUM 2] Başlatma Dizisi 1 (Resetleme Denemesi)
                -- LCD'ye "Uyan" (0x03) komutu gönderilir.
                when init_seq_1 => 
                    clk_count := clk_count + 1; 
                    if (clk_count < (1*freq)) then       -- 1. Adım: Veriyi hazırla
                        E <= '0'; D <= "0011"; 
                    elsif (clk_count < (3*freq)) then    -- 2. Adım: Enable High (Pulse)
                        E <= '1';
                    elsif (clk_count < (4*freq)) then    -- 3. Adım: Enable Low (Veriyi yaz)
                        E <= '0';
                    elsif (clk_count < (5000*freq)) then -- 4. Adım: LCD'nin işlemesi için bekle (5ms)
                        -- bekleme
                    else             
                        clk_count := 0;
                        state <= init_seq_2;            
                    end if;
             
                -- [DURUM 3] Başlatma Dizisi 2
                -- Tekrar 0x03 gönderilir (Datasheet gereği).
                when init_seq_2 =>
                    clk_count := clk_count + 1; 
                    if (clk_count < (1*freq)) then 
                        E <= '0'; D <= "0011"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (200*freq)) then -- 200us bekle
                        -- bekleme
                    else             
                        clk_count := 0;
                        state <= init_seq_3;            
                    end if; 
                    
                -- [DURUM 4] Başlatma Dizisi 3
                -- Son kez 0x03 gönderilir.
                when init_seq_3 =>
                    clk_count := clk_count + 1; 
                    if (clk_count < (1*freq)) then 
                        E <= '0'; D <= "0011"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (200*freq)) then
                        -- bekleme
                    else             
                        clk_count := 0;
                        state <= init_seq_4;            
                    end if;
                    
                -- [DURUM 5] 4-Bit Moduna Geçiş
                -- LCD'ye 0x02 göndererek "Artık 4 kablo ile konuşacağız" denir.
                when init_seq_4 =>
                    clk_count := clk_count + 1; 
                    if (clk_count < (1*freq)) then 
                        E <= '0'; D <= "0010"; -- 0x2
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (200*freq)) then
                        -- bekleme
                    else             
                        clk_count := 0;
                        state <= send_func_set;            
                    end if;
                    
                -- [DURUM 6] Function Set Ayarı (0x28)
                -- 4-bit modu, 2 satır, 5x8 font ayarı yapılır.
                -- ARTIK VERİLER İKİ PARÇA (NIBBLE) HALİNDE GİDER.
                when  send_func_set =>
                    clk_count := clk_count + 1;
                    
                    -- Üst 4 bit (High Nibble): 0010
                    if (clk_count < (1*freq)) then
                        E <= '0'; D <= "0010"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    
                    -- Parçalar arası minik bekleme
                    elsif (clk_count < (5*freq)) then 
                        -- boşluk
                    
                    -- Alt 4 bit (Low Nibble): 1000
                    elsif (clk_count < (6*freq)) then
                        D <= "1000"; 
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    
                    -- Komut işleme süresi
                    elsif (clk_count < (60*freq)) then 
                        -- bekleme
                    else         
                        clk_count := 0;
                        state <= send_display_off;       
                    end if;
                    
                -- [DURUM 7] Ekranı Kapat (0x08)
                -- Ayarlar yapılırken ekranın titrememesi için kapatılır.
                when send_display_off =>
                    clk_count := clk_count + 1;
                    -- High Nibble: 0000
                    if (clk_count < (1*freq)) then
                        E <= '0'; D <= "0000"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (5*freq)) then 
                    -- Low Nibble: 1000 (0x8)
                    elsif (clk_count < (6*freq)) then
                        D <= "1000"; 
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    elsif (clk_count < (60*freq)) then 
                    else         
                        clk_count := 0;
                        state <= send_clear;       
                    end if;
                    
                -- [DURUM 8] Ekranı Temizle (0x01)
                -- Ekrandaki tüm karakterleri siler. BU KOMUT UZUN SÜRER!
                when send_clear =>
                    clk_count := clk_count + 1;
                    -- High Nibble: 0000
                    if (clk_count < (1*freq)) then
                        E <= '0'; D <= "0000"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (5*freq)) then 
                    -- Low Nibble: 0001
                    elsif (clk_count < (6*freq)) then
                        D <= "0001"; 
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    -- DİKKAT: Clear komutu için 2ms (2000us) beklenmeli!
                    elsif (clk_count < (2000*freq)) then 
                         -- Uzun bekleme
                    else         
                        clk_count := 0;
                        state <= send_entry_mode;       
                    end if;
                    
                -- [DURUM 9] Entry Mode Set (0x06)
                -- Yazı yazdıkça imlecin sağa kaymasını sağlar (Auto Increment).
                when send_entry_mode =>
                    clk_count := clk_count + 1;
                    -- High Nibble: 0000
                    if (clk_count < (1*freq)) then
                        E <= '0'; D <= "0000"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (5*freq)) then 
                    -- Low Nibble: 0110 (0x6)
                    elsif (clk_count < (6*freq)) then
                        D <= "0110"; 
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    elsif (clk_count < (60*freq)) then 
                    else         
                        clk_count := 0;
                        state <= send_display_on;       
                    end if;

                -- [DURUM 10] Ekranı Aç (0x0C)
                -- Ekranı açar, imleci (cursor) gizler.
                when send_display_on =>
                      clk_count := clk_count + 1;
                    -- High Nibble: 0000
                    if (clk_count < (1*freq)) then
                        E <= '0'; D <= "0000"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (5*freq)) then 
                    -- Low Nibble: 1100 (0xC)
                    elsif (clk_count < (6*freq)) then
                        D <= "1100"; 
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    elsif (clk_count < (60*freq)) then 
                    else         
                        clk_count := 0;
                        state <= line1; -- Artık yazı yazmaya hazırız!      
                    end if;

                -- [DURUM 11] 1. Satırı Yazma Döngüsü
                when line1 =>
                    clk_count := clk_count + 1;
                    RS <= '1'; -- ÖNEMLİ: Veri gönderiyoruz (RS=1)
                    
                    -- High Nibble Gönderimi
                    if (clk_count < (1*freq)) then
                        -- Array'den sıradaki harfin üst 4 bitini al
                        D <= line1_data(ptr)(7 downto 4); 
                        E <= '0'; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (5*freq)) then 
                        -- bekle
                    -- Low Nibble Gönderimi
                    elsif (clk_count < (6*freq)) then
                        -- Array'den sıradaki harfin alt 4 bitini al
                        D <= line1_data(ptr)(3 downto 0);
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    elsif (clk_count < (60*freq)) then 
                         -- Karakterin yazılması için bekle
                    else         
                        clk_count := 0;
                        -- Pointer kontrolü: Satır bitti mi?
                        if ptr < 15 then 
                           ptr <= ptr + 1; -- Bir sonraki harfe geç
                        else
                           ptr <= 0; -- Pointer'ı sıfırla
                           state <= ch_line; -- 2. Satıra geçme komutuna git
                        end if;
                    end if;
            
                -- [DURUM 12] 2. Satıra Geçiş Komutu (0xC0)
                -- LCD adresini 0x40 (2. satır başı) yapar.
                when ch_line =>
                    clk_count := clk_count + 1;
                    RS <= '0'; -- Bu bir komuttur (RS=0)
                    
                    -- High Nibble: 1100 (0xC)
                    if (clk_count < (1*freq)) then
                        E <= '0'; D <= "1100"; 
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (5*freq)) then 
                    
                    -- Low Nibble: 0000 (0x0)
                    elsif (clk_count < (6*freq)) then
                        D <= "0000"; 
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    elsif (clk_count < (60*freq)) then 
                    else         
                        clk_count := 0;
                        state <= line2; -- 2. Satıra yazmaya başla     
                    end if;

                -- [DURUM 13] 2. Satırı Yazma Döngüsü
                when line2 =>
                    clk_count := clk_count + 1;
                    RS <= '1'; -- Veri (RS=1)
                    
                    -- High Nibble
                    if (clk_count < (1*freq)) then
                        D <= line2_data(ptr)(7 downto 4); 
                        E <= '0';
                    elsif (clk_count < (3*freq)) then
                        E <= '1';
                    elsif (clk_count < (4*freq)) then
                        E <= '0';
                    elsif (clk_count < (5*freq)) then 
                    
                    -- Low Nibble
                    elsif (clk_count < (6*freq)) then
                         D <= line2_data(ptr)(3 downto 0); 
                    elsif (clk_count < (8*freq)) then
                        E <= '1';
                    elsif (clk_count < (9*freq)) then
                        E <= '0';
                    elsif (clk_count < (60*freq)) then 
                    else         
                        clk_count := 0;
                        if ptr < 15 then
                           ptr <= ptr + 1;
                        else
                           state <= finish; -- Tüm yazma bitti
                        end if;
                    end if;
                
                -- [DURUM 14] Bitiş
                -- Sonsuz döngüde bekle. Ekran sabit kalır.
                when finish =>
                    state <= finish;                                     
            end case;
        end if;
    end process;                                   
end Behavioral;
