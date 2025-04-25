library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART
entity pong_graph_st is
    port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(4 downto 0);--- updated bits to 5 
        video_on: in std_logic;
        hit_cnt: out std_logic_vector (2 downto 0);
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end pong_graph_st;

architecture sq_ball_arch of pong_graph_st is
-- Signal used to control speed of ball and how
-- often pushbuttons are checked for paddle movement.
    signal refr_tick: std_logic;

-- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);

-- screen dimensions
    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;

-- wall left and right boundary of wall (full height)
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;
 
-- paddle left, right, top, bottom and height left &
-- right are constant. top & bottom are signals to
-- allow movement. bar_y_t driven by reg below.

    --constant BAR_X_L: integer:=600;
    --constant BAR_X_R: integer := 603;

    signal bar_x_l, bar_x_r: unsigned(9 downto 0);
    signal bar_y_t, bar_y_b: unsigned(9 downto 0);

    --constant BAR_Y_SIZE: integer := 72;
    --constant BAR_X_SIZE: integer := 8; ---new 
    constant BAR_SIZE: integer := 16;
-- reg to track top boundary 
    signal bar_y_reg, bar_y_next: unsigned(9 downto 0);
    signal bar_x_reg, bar_x_next: unsigned(9 downto 0);----new 


    signal bool_l, bool_r: std_logic;
    signal bool_lr: std_logic_vector(1 downto 0);
-- bar moving velocity when a button is pressed
-- the amount the bar is moved.

    constant BAR_V: integer:= 4;
    constant BAR_H: integer:= 2;

--  First asteriod  -- asteriod left, right, top and bottom
-- all vary. Left and top driven by registers below.
    constant ASTEROID_ONE_SIZE: integer := 8;
    signal asteroidOne_x_l, asteroidOne_x_r: unsigned(9 downto 0);
    signal asteroidOne_y_t, asteroidOne_y_b: unsigned(9 downto 0);



    --- reg to track left and top boundary
    signal asteroidOne_x_reg, asteroidOne_x_next: unsigned(9 downto 0);
    signal asteroidOne_y_reg, asteroidOne_y_next: unsigned(9 downto 0);

    --- Second Asteriod 
    -------------------------------------------------------------------------
      constant ASTEROID_TW0_SIZE: integer := 8;
      signal asteroidTwo_x_l, asteroidTwo_x_r: unsigned(9 downto 0);
      signal asteroidTwo_y_t, asteroidTwo_y_b: unsigned(9 downto 0);


   --- reg to track left and top boundary
    signal asteroidTwo_x_reg, asteroidTwo_x_next: unsigned(9 downto 0);
    signal asteroidTwo_y_reg, asteroidTwo_y_next: unsigned(9 downto 0);


    ---- Third Asteriod 
    -------------------------------------------------------------------------
    constant ASTEROID_THREE_SIZE: integer := 8;
      signal asteroidThree_x_l, asteroidThree_x_r: unsigned(9 downto 0);
      signal asteroidThree_y_t, asteroidThree_y_b: unsigned(9 downto 0);


   --- reg to track left and top boundary
    signal asteroidThree_x_reg, asteroidThree_x_next: unsigned(9 downto 0);
    signal asteroidThree_y_reg, asteroidThree_y_next: unsigned(9 downto 0);



    ------------------------------------------------------------------------------------
    -- reg to track aestoroids speeds
    signal x_asteroidOne_delta_reg, x_asteroidOne_delta_next: unsigned(9 downto 0);
    signal y_asteroidOne_delta_reg, y_asteroidOne_delta_next: unsigned(9 downto 0);

    signal x_asteroidTwo_delta_reg, x_asteroidTwo_delta_next: unsigned(9 downto 0);
    signal y_asteroidTwo_delta_reg, y_asteroidTwo_delta_next: unsigned(9 downto 0);

    signal x_asteroidThree_delta_reg, x_asteroidThree_delta_next: unsigned(9 downto 0);
    signal y_asteroidThree_delta_reg, y_asteroidThree_delta_next: unsigned(9 downto 0);


    -- asteroid movement One can be pos or neg
    constant asteroidOne_V_P: unsigned(9 downto 0):= to_unsigned(1,10);
    constant asteroidOne_V_N: unsigned(9 downto 0):= unsigned(to_signed(-1,10));



    -- asteroid movement Two can be pos or neg
    constant asteroidTwo_V_P: unsigned(9 downto 0):= to_unsigned(2,10);
    constant asteroidTwo_V_N: unsigned(9 downto 0):= unsigned(to_signed(-2,10));

     -- asteroid movement Three can be pos or neg
    constant asteroidThree_V_P: unsigned(9 downto 0):= to_unsigned(3,10);
    constant asteroidThree_V_N: unsigned(9 downto 0):= unsigned(to_signed(-3,10));




    
    --firing ball dimensions and signals 
    
    constant FIRING_SIZE: integer := 10;
    signal firing_ball_x_l, firing_ball_x_r: unsigned(9 downto 0);
    signal firing_ball_y_t, firing_ball_y_b: unsigned(9 downto 0);
    signal firing_ball_x_reg, firing_ball_y_reg: unsigned(9 downto 0);--- new
    signal firing_ball_y_next , firing_ball_x_next: unsigned(9 downto 0);--new  
    
    --- firing ball speed registers 
    signal x_delta_firing_reg, x_delta_firing_next: unsigned(9 downto 0);
    signal y_delta_firing_reg, y_delta_firing_next: unsigned(9 downto 0);
    
    
    
--- firing ball movements 
    constant FIRING_BALL_V_P: unsigned(9 downto 0):= to_unsigned(2,10);

-- Ship shape
   type bar_rom_type is array(0 to 15) of std_logic_vector(0 to 15);-- new 
   constant BAR_ROM: bar_rom_type:= (
    "00000000011000000000011000000000",
    "00000000011000000000011000000000",
    "00000000111100000000111100000000",
    "00000000111100000000111100000000",
    "00000000111100000000111100000000",
    "00000000111100000000111100000000",
    "00000000111100000000111100000000",
    "00000000111100000000111100000000",
    "00000000111111111111111100000000",
    "00000000111111111111111100000000",
    "00000000111111111111111100000000",
    "00000000111111111111111100000000",
    "00000000111111111111111100000000",
    "00000000111111111111111100000000",
    "00000001111111111111111110000000",
    "00000001111111111111111110000000",
    "00000001111111111111111110000000",
    "00000011111111111111111111000000",
    "00000011111111111111111111000000",
    "00000011111111111111111111000000",
    "00000111111111111111111111100000",
    "00000111111111111111111111100000",
    "00000110111011100001100001100000",
    "00001110111011111101111101110000",
    "00001110111011111101111101110000",
    "00011110000011100001100001110000",
    "00011110111111101111111101111000",
    "00011110111111101111111101111000",
    "00011110111111100001100001111100",
    "01111111111111111111111111111110",
    "00000111100000000000001111000000",
    "00000111100000000000001111000000"
    );
 
    -- ROM for bar
       signal bar_rom_addr, bar_rom_col: unsigned(3 downto 0);
       signal bar_rom_data: std_logic_vector(15 downto 0);
       signal bar_rom_bit: std_logic;
 
 -- round asteriod  One  image
    type asteriodOne_rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant ASTERIODONE_ROM: asteriodOne_rom_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11111110",
        "11111111",
        "11111111",
        "01111110",
        "00111100");


    signal asteroidOne_rom_addr, asteroidOne_rom_col: unsigned(2 downto 0);
    signal asteroidOne_rom_data: std_logic_vector(7 downto 0);
    signal asteroidOne_rom_bit: std_logic; 



-- round asteriod  Two image
    type asteriodTwo_rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant ASTEROIDTWO_ROM: asteriodTwo_rom_type:= (
        "00111100",
        "01111110",
        "01111111",
        "00111111",
        "11111111",
        "11111110",
        "01111110",
        "00111100");


    signal asteroidTwo_rom_addr, asteroidTwo_rom_col: unsigned(2 downto 0);
    signal asteroidTwo_rom_data: std_logic_vector(7 downto 0);
    signal asteroidTwo_rom_bit: std_logic; 



-- round asteriod  Three image
    type asteriodThree_rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant ASTEROIDTHREE_ROM: asteriodThree_rom_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11111111",
        "11111111",
        "11111111",
        "01111110",
        "00111100");


    signal asteroidThree_rom_addr, asteroidThree_rom_col: unsigned(2 downto 0);
    signal asteroidThree_rom_data: std_logic_vector(7 downto 0);
    signal asteroidThree_rom_bit: std_logic; 

    
    -- ROM types and constants for for firing ball as well as image  
    type firing_rom_type is array(0 to 15) of std_logic_vector(0 to 15);
    constant FIRING_ROM: firing_rom_type := (
        "0000111111110000",
        "0001111111111000",
        "0011111111111100",
        "0111000000001110",
        "1110011111100111",
        "1100111111110011",
        "1100111111110011",
        "1100111111110001",
        "1100111111110011",
        "1100111111110011",
        "1100111111110011",
        "1100011111100011",
        "0110011111100110",
        "0011000000001100",
        "0001111111111000",
        "0000111111110000"
    );
    signal firing_rom_addr, firing_rom_col: unsigned(3 downto 0);
    signal firing_rom_data: std_logic_vector(15 downto 0);
    signal firing_rom_bit: std_logic;
    
-- object output signals -- new signal to indicate if
-- scan coord is within ball
    signal wall_on, bar_on , sq_bar_on : std_logic;
    signal sq_asteroidOne_on, sq_asteroidTwo_on, sq_asteroidThree_on : std_logic;
    signal rd_asteroidOne_on, rd_asteroidTwo_on, rd_asteroidThree_on : std_logic;

    signal sq_firing_ball_on, rd_firing_ball_on: std_logic; --- new firing ball image 
    signal wall_rgb, bar_rgb : std_logic_vector(2 downto 0);
     signal hit_cnt_reg, hit_cnt_next: unsigned (2 downto 0);
    signal asteroidOne_rgb, asteroidTwo_rgb, asteroidThree_rgb, firing_ball_rgb: std_logic_vector(2 downto 0);
    
-- ====================================================
    begin
        process (clk, reset)
            begin
                if (reset = '1') then
                    bar_y_reg <= (others => '0');
                    bar_x_reg <=(others => '0');---new
                    hit_cnt_reg<=(others => '0');

                    asteroidOne_x_reg <= (others => '0'); 
                    asteroidOne_y_reg <= (others => '0');
                    asteroidTwo_x_reg <= (others => '0'); 
                    asteroidTwo_y_reg <= (others => '0');
                    asteroidThree_x_reg <= (others => '0'); 
                    asteroidThree_y_reg <= (others => '0');
                    
                    
                    x_asteroidOne_delta_reg <= ("0000000100");
                    y_asteroidOne_delta_reg <= ("0000000100"); 

                    x_asteroidTwo_delta_reg <= ("0000000100");
                    y_asteroidTwo_delta_reg <= ("0000000100"); 

                    x_asteroidThree_delta_reg <= ("0000000100");
                    y_asteroidThree_delta_reg <= ("0000000100");


                    firing_ball_x_reg <=(others => '0');--new initialization
                    firing_ball_y_reg <=(others => '0');--new  inititialization 

                    
                elsif (clk'event and clk = '1') then
                    bar_y_reg <= bar_y_next;
                    bar_x_reg <= bar_x_next;-- new 

                    hit_cnt_reg<= hit_cnt_next;
                    
                    asteroidOne_x_reg <= asteroidOne_x_next;
                    asteroidOne_y_reg <= asteroidOne_y_next;

                    asteroidTwo_x_reg <= asteroidTwo_x_next;
                    asteroidTwo_y_reg <= asteroidTwo_y_next;

                    asteroidThree_x_reg <= asteroidThree_x_next;
                    asteroidThree_y_reg <= asteroidThree_y_next;
                       
                    
                    x_asteroidOne_delta_reg <= x_asteroidOne_delta_next;
                    y_asteroidOne_delta_reg <= y_asteroidOne_delta_next;


                    x_asteroidTwo_delta_reg <= x_asteroidTwo_delta_next;
                    y_asteroidTwo_delta_reg <= y_asteroidTwo_delta_next;

                    x_asteroidThree_delta_reg <= x_asteroidThree_delta_next;
                    y_asteroidThree_delta_reg <= y_asteroidThree_delta_next;


                    firing_ball_x_reg <= firing_ball_x_next;---new update  output only when the rising edge of the clock 
                    firing_ball_y_reg <= firing_ball_y_next;---new   

                end if;
        end process;
        
        
       ----pixel coordinates 
       
        pix_x <= unsigned(pixel_x);
        pix_y <= unsigned(pixel_y);
        
-- refr_tick: 1-clock tick asserted at start of v_sync,
-- e.g., when the screen is refreshed -- speed is 60 Hz
        refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) else '0';

-- wall left vertical stripe
        wall_on <= '1' when (WALL_X_L <= pix_x) and (pix_x <= WALL_X_R) else '0';
        wall_rgb <= "001"; -- blue

-- pixel within paddle

        bar_x_l <= bar_x_reg;-- new 
        bar_x_r <= bar_x_l + 16 - 1;-- new 
        bar_y_t <= bar_y_reg;
        bar_y_b <= bar_y_t + 16 - 1;
        
        sq_bar_on <= '1' when (bar_x_l <= pix_x) and (pix_x <= bar_x_r) and (bar_y_t <= pix_y) and (pix_y <= bar_y_b) 
            else '0';
        bar_rgb <= "101"; -- magenta


-- Process bar movement requests ( UP AND DOWN)
        process( bar_y_reg, bar_y_b, bar_y_t, refr_tick, btn)
            begin
                bar_y_next <= bar_y_reg; -- no move
                if ( refr_tick = '1' ) then
-- if btn 1 pressed and paddle not at bottom yet
                    if ( btn(1) = '1' and bar_y_b < (MAX_Y - 1 - BAR_V)) then
                        bar_y_next <= bar_y_reg + BAR_V;
-- if btn 0 pressed and bar not at top yet
                    elsif ( btn(0) = '1' and bar_y_t >  BAR_V) then
                        bar_y_next <= bar_y_reg - BAR_V;
                    end if;
                end if;
        end process;


--horizontal bar movement
        bool_l <= '1' when (btn(2) = '1') and (bar_x_l > (BAR_H)) else '0';
        bool_r <= '1' when (btn(3) = '1') and (bar_x_r < MAX_X - 1 - BAR_H) else '0';
          
        
         bool_lr <= bool_l & bool_r;
        
        process(bar_x_reg, bar_x_r, bar_x_l, refr_tick, btn)
            begin
                bar_x_next <= bar_x_reg;
                if(refr_tick = '1') then
                    case bool_lr is
                        when "00" =>
                            bar_x_next <= bar_x_reg;
                        when "01" =>
                            bar_x_next <= bar_x_reg + BAR_H;
                        when "10" =>
                            bar_x_next <= bar_x_reg - BAR_H;
                        when others =>
                            bar_x_next <= bar_x_reg;
                    end case;
                end if;
         end process;





-- set coordinates of  first square  asteriod.
        asteroidOne_x_l <= asteroidOne_x_reg;
        asteroidOne_y_t <= asteroidOne_y_reg;
        asteroidOne_x_r <= asteroidOne_x_l + ASTEROID_ONE_SIZE - 1;
        asteroidOne_y_b <= asteroidOne_y_t + ASTEROID_ONE_SIZE - 1;



-- set coordinates of  second square  asteriod.
        asteroidTwo_x_l <= asteroidTwo_x_reg;
        asteroidTwo_y_t <= asteroidTwo_y_reg;
        asteroidTwo_x_r <= asteroidTwo_x_l + ASTEROID_TW0_SIZE - 1;
        asteroidTwo_y_b <= asteroidTwo_y_t + ASTEROID_TW0_SIZE - 1;


-- set coordinates of  Third square  asteriod.
        asteroidThree_x_l <= asteroidThree_x_reg;
        asteroidThree_y_t <= asteroidThree_y_reg;
        asteroidThree_x_r <= asteroidThree_x_l + ASTEROID_THREE_SIZE - 1;
        asteroidThree_y_b <= asteroidThree_y_t + ASTEROID_THREE_SIZE - 1;




        
-- set coordinates of firing ball

        firing_ball_x_l <= firing_ball_x_reg;
        firing_ball_y_t <= firing_ball_y_reg;
        firing_ball_x_r <= firing_ball_x_l + FIRING_SIZE - 1;
        firing_ball_y_b <= firing_ball_y_t + FIRING_SIZE - 1;
        
 -- pixel within  First square ball
        sq_asteroidOne_on <= '1' when (asteroidOne_x_l <= pix_x) and
         (pix_x <= asteroidOne_x_r) and (asteroidOne_y_t <= pix_y) and 
         (pix_y <= asteroidOne_y_b) else '0';


-- pixel within  Second square ball
        sq_asteroidTwo_on <= '1' when (asteroidTwo_x_l <= pix_x) and
         (pix_x <= asteroidTwo_x_r) and (asteroidTwo_y_t <= pix_y) and 
         (pix_y <= asteroidTwo_y_b) else '0';

-- pixel within  Third square ball
        sq_asteroidThree_on <= '1' when (asteroidThree_x_l <= pix_x) and
         (pix_x <= asteroidThree_x_r) and (asteroidThree_y_t <= pix_y) and 
         (pix_y <= asteroidThree_y_b) else '0';
         
 
----pixel within spaceship         
        sq_bar_on <= '1' when (bar_x_l <= pix_x) and 
        (pix_x <= bar_x_r) and (bar_y_t <= pix_y) and
        (pix_y <= bar_y_b) else '0';
        
        bar_on <= '1' when (sq_bar_on = '1') and 
        (asteroidTwo_rom_bit = '1') else '0';
         




        
---pixel within firing ball
        sq_firing_ball_on <= '1' when (firing_ball_x_l <= pix_x) and 
        (pix_x <= firing_ball_x_r) and (firing_ball_y_t <= pix_y) and
         (pix_y <= firing_ball_y_b) else '0';

-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.

-- ROM to display bar 

        bar_rom_addr <= pix_y(3 downto 0) - bar_y_t(3 downto 0);---- new 
        bar_rom_col <= pix_x(3 downto 0) - bar_x_l(3 downto 0);
        bar_rom_data <= BAR_ROM(to_integer(bar_rom_addr));
        bar_rom_bit <= bar_rom_data(to_integer(bar_rom_col));

-- ASTEROID ONE ROM row
        asteroidOne_rom_addr <= pix_y(2 downto 0) - asteroidOne_y_t(2 downto 0);
-- ROM column
        asteroidOne_rom_col <= pix_x(2 downto 0) - asteroidOne_x_l(2 downto 0);
-- Get row data
        asteroidOne_rom_data <= ASTERIODONE_ROM(to_integer(asteroidOne_rom_addr));


-- ASTEROID TWO ROM row
        asteroidTwo_rom_addr <= pix_y(2 downto 0) - asteroidTwo_y_t(2 downto 0);
-- ROM column
        asteroidTwo_rom_col <= pix_x(2 downto 0) - asteroidTwo_x_l(2 downto 0);
-- Get row data
        asteroidTwo_rom_data <= ASTEROIDTWO_ROM(to_integer(asteroidTwo_rom_addr));



 -- ASTEROID THREE ROM row
        asteroidThree_rom_addr <= pix_y(2 downto 0) - asteroidThree_y_t(2 downto 0);
-- ROM column
        asteroidThree_rom_col <= pix_x(2 downto 0) - asteroidThree_x_l(2 downto 0);
-- Get row data
        asteroidThree_rom_data <= ASTEROIDTHREE_ROM(to_integer(asteroidThree_rom_addr));       
  
        
-- FIRING ROM  row
        firing_rom_addr <= pix_y(3 downto 0) - firing_ball_y_t(3 downto 0);
-- FIRING ROM column
        firing_rom_col <= pix_x(3 downto 0) - firing_ball_x_l(3 downto 0);
-- Get  FIRING row data
        firing_rom_data <= FIRING_ROM(to_integer(firing_rom_addr));
        
        
        
-- Get  First asteroid column bit
        asteroidOne_rom_bit <= asteroidOne_rom_data(to_integer(asteroidOne_rom_col));


-- Get  Second  asteroid column bit
        asteroidTwo_rom_bit <= asteroidTwo_rom_data(to_integer(asteroidTwo_rom_col));



-- Get  Third  asteroid column bit
        asteroidThree_rom_bit <= asteroidThree_rom_data(to_integer(asteroidThree_rom_col));

        
 --- Get firing ball column bit
        firing_rom_bit <= firing_rom_data(to_integer(firing_rom_col));
        
-- Turn first asteroid on only if within square and ROM bit is 1.
        rd_asteroidOne_on <= '1' when (sq_asteroidOne_on = '1') and (asteroidOne_rom_bit = '1') else '0';
        asteroidOne_rgb <= "100"; -- red 


-- Turn second asteroid  on only if within square and ROM bit is 1.
        rd_asteroidTwo_on <= '1' when (sq_asteroidTwo_on = '1') and (asteroidTwo_rom_bit = '1') else '0';
        asteroidTwo_rgb <= "010"; -- green 


-- Turn Third asteroid  on only if within square and ROM bit is 1.
        rd_asteroidThree_on <= '1' when (sq_asteroidThree_on = '1') and (asteroidThree_rom_bit = '1') else '0';
        asteroidThree_rgb <= "001"; -- blue

---- Turn firing ball on only if within square and ROM bit is 1.
        rd_firing_ball_on <= '1' when (sq_firing_ball_on = '1') and (firing_rom_bit = '1') else '0';
        firing_ball_rgb <= "100";--red 
        
        

        
-- Update the first asteroid position 60 times per second.
        asteroidOne_x_next <= asteroidOne_x_reg + x_asteroidOne_delta_reg when  
        refr_tick = '1' else asteroidOne_x_reg;
        asteroidOne_y_next <= asteroidOne_y_reg + y_asteroidOne_delta_reg when
        refr_tick = '1' else asteroidOne_y_reg;

-- Update the second asteroid position 60 times per second.
        asteroidTwo_x_next <= asteroidTwo_x_reg + x_asteroidTwo_delta_reg when  
        refr_tick = '1' else asteroidOne_x_reg;
        asteroidTwo_y_next <= asteroidTwo_y_reg + y_asteroidTwo_delta_reg when
        refr_tick = '1' else asteroidTwo_y_reg;


-- Update the Third asteroid position 60 times per second.
        asteroidThree_x_next <= asteroidThree_x_reg + x_asteroidThree_delta_reg when  
        refr_tick = '1' else asteroidOne_x_reg;
        asteroidThree_y_next <= asteroidThree_y_reg + y_asteroidThree_delta_reg when
        refr_tick = '1' else asteroidThree_y_reg;

-- Set the value of the next ball position according to
-- the boundaries.

        process(x_asteroidOne_delta_reg, y_asteroidOne_delta_reg, asteroidOne_y_t , asteroidOne_y_b, asteroidOne_x_r, asteroidOne_x_l,
         bar_y_t, bar_y_b,bar_x_r , bar_x_l )
          begin
                x_asteroidOne_delta_next <= x_asteroidOne_delta_reg;
                y_asteroidOne_delta_next <= y_asteroidOne_delta_reg;

                --  if First Asteroid reached top, make offset positive
                if (asteroidOne_y_t < 1) then
                    y_asteroidOne_delta_next <= asteroidOne_V_P;
 -- reached bottom, make negative
                elsif (asteroidOne_y_b > (MAX_Y - 1)) then
                    y_asteroidOne_delta_next <= asteroidOne_V_N;
-- reach wall, bounce back
                elsif (asteroidOne_x_l <= WALL_X_R ) then
                    x_asteroidOne_delta_next <= asteroidOne_V_P;
-- right corner of ball inside bar
                elsif ((bar_x_l <= asteroidOne_x_r) and (asteroidOne_x_r <= bar_x_r)) then
-- some portion of ball hitting paddle, reverse dir
                    if ((bar_y_t <= asteroidOne_y_b) and (asteroidOne_y_t <= bar_y_b)) then
                        x_asteroidOne_delta_next <= asteroidOne_V_N;
                    end if;
                end if;

        end process;


        process(x_asteroidTwo_delta_reg, y_asteroidTwo_delta_reg, asteroidTwo_y_t, asteroidTwo_y_b, asteroidTwo_x_l, bar_y_t, bar_y_b, asteroidTwo_x_r)
         begin
                 x_asteroidTwo_delta_next <= x_asteroidTwo_delta_reg;
                 y_asteroidTwo_delta_next <= y_asteroidTwo_delta_reg;
        
        --  if Second  Asteroid reached top, make offset positive
                if (asteroidTwo_y_t < 1) then
                    y_asteroidTwo_delta_next <= asteroidTwo_V_P;
 -- reached bottom, make negative
                elsif (asteroidTwo_y_b > (MAX_Y - 1)) then
                    y_asteroidTwo_delta_next <= asteroidTwo_V_N;
-- reach wall, bounce back
                elsif (asteroidTwo_x_l <= WALL_X_R) then
                    x_asteroidTwo_delta_next <= asteroidTwo_V_P;
-- right corner of ball inside bar
                elsif ((bar_x_l <= asteroidTwo_x_r) and (asteroidTwo_x_r <= bar_x_r)) then
-- some portion of ball hitting paddle, reverse dir
                    if ((bar_y_t <= asteroidTwo_y_b) and (asteroidTwo_y_t <= bar_y_b)) then
                        x_asteroidTwo_delta_next <= asteroidTwo_V_N;
                    end if;
                end if;
          end process;


process(asteroidThree_y_t, asteroidThree_y_b, asteroidThree_x_r, asteroidThree_x_l, bar_y_t, bar_y_b, y_asteroidThree_delta_reg, bar_x_l, bar_x_r)
         begin
          x_asteroidThree_delta_next <= x_asteroidThree_delta_reg;
          y_asteroidThree_delta_next <= y_asteroidThree_delta_reg;
        --  if Third  Asteroid reached top, make offset positive
                if ( asteroidThree_y_t < 1 ) then
                    y_asteroidThree_delta_next <= asteroidThree_V_P;
 -- reached bottom, make negative
                elsif (asteroidThree_y_b > (MAX_Y - 1)) then
                    y_asteroidThree_delta_next <= asteroidThree_V_N;
-- reach wall, bounce back
                elsif (asteroidThree_x_l <= WALL_X_R ) then
                    x_asteroidThree_delta_next <= asteroidThree_V_P;
-- right corner of ball inside bar
                elsif ((bar_x_l <= asteroidThree_x_r) and (asteroidThree_x_r <= bar_x_r)) then
-- some portion of ball hitting paddle, reverse dir
                    if ((bar_y_t <= asteroidThree_y_b) and (asteroidThree_y_t <= bar_y_b)) then
                        x_asteroidThree_delta_next <= asteroidThree_V_N;
                    end if;
                end if;
       end process;


        process (firing_ball_x_reg, firing_ball_y_reg, refr_tick, btn , bar_y_reg, bar_x_reg,  bar_x_l, firing_ball_x_r)
            begin
                --- default values 
            firing_ball_x_next<= firing_ball_x_reg;
            firing_ball_y_next <= firing_ball_y_reg;
                
            if (refr_tick = '1') then
                -- Reset firing ball position if firing button is pressed
                if (btn(4)='1') then
                    firing_ball_x_next <= bar_x_l; -- Set firing ball x position to bar position & unisgned 
                    firing_ball_y_next <= bar_y_reg; -- Set firing ball y position to bar position
                else
                    -- Move firing ball horizontally
                    if (firing_ball_x_r > 0 and  firing_ball_x_reg < MAX_X )then
                        firing_ball_x_next <= firing_ball_x_reg - asteroidOne_V_P; -- Move left
                    end if;
                end if;
            end if;
        end process;

        
 
        process (video_on, wall_on, bar_on, rd_asteroidOne_on, rd_asteroidTwo_on, rd_asteroidThree_on,
         wall_rgb, bar_rgb,asteroidOne_rgb, asteroidTwo_rgb , asteroidThree_rgb , rd_firing_ball_on, firing_ball_rgb )

            begin
                if (video_on = '0') then
                    graph_rgb <= "000"; -- blank
                else

                    if(rd_firing_ball_on = '1') then
                        graph_rgb <= firing_ball_rgb;
                    elsif (wall_on = '1') then-- new
                        graph_rgb <= wall_rgb;
                    elsif (bar_on = '1') then
                        graph_rgb <= bar_rgb;
                    elsif (rd_asteroidOne_on = '1') then
                        graph_rgb <= asteroidOne_rgb;
                    elsif (rd_asteroidTwo_on = '1') then
                        graph_rgb <= asteroidTwo_rgb;
                    elsif (rd_asteroidThree_on = '1') then
                        graph_rgb <= asteroidThree_rgb;
                    else
                        graph_rgb <= "011"; -- cyan
                    end if;
                end if;
              
        end process;
        
        
         hit_cnt_next <= hit_cnt_reg+1 when ((bar_x_l < asteroidOne_x_r)
                               and (asteroidOne_x_r < bar_x_l + asteroidOne_V_P)
                               and (x_asteroidOne_delta_reg = asteroidOne_V_N)
                               and (bar_y_t < asteroidOne_y_b)
                               and (asteroidOne_y_t < bar_y_b)
                               and refr_tick = '1')
                               else hit_cnt_reg;
                               
                               
                               
--          hit_cnt_next <= hit_cnt_reg+1 when ((bar_x_l < asteroidTwo_x_r)
--                               and (asteroidTwo_x_r < bar_x_l + asteroidTwo_V_P)
--                               and (x_asteroidTwo_delta_reg = asteroidTwo_V_N)
--                               and (bar_y_t < asteroidTwo_y_b)
--                               and (asteroidTwo_y_t < bar_y_b)
--                               and refr_tick = '1')
--                               else hit_cnt_reg;
                               
                               
--           hit_cnt_next <= hit_cnt_reg+1 when ((bar_x_l < asteroidThree_x_r)
--                               and (asteroidThree_x_r < bar_x_l + asteroidTwo_V_P)
--                               and (x_asteroidThree_delta_reg = asteroidThree_V_N)
--                               and (bar_y_t < asteroidThree_y_b)
--                               and (asteroidThree_y_t < bar_y_b)
--                               and refr_tick = '1')
--                               else hit_cnt_reg;
                               
                               
                               
                               
                               
   -- output logic
   hit_cnt <= std_logic_vector(hit_cnt_reg);
                            
     
end sq_ball_arch;

