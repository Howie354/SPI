module spi_master_top #(
    parameter DATA_WIDTH = 8,
    parameter SCLK_CNT   = 10
) (
    input                       clk,
    input                       rst_n,

    input  [2*DATA_WIDTH : 0]   cmd_in,
    input                       cmd_vld,
    output                      cmd_rdy,

    output                      m_read_vld,
    output [DATA_WIDTH - 1 : 0] m_read_data,

    output                      sclk,
    output                      cs_n,
    
    output                      mosi,
    input                       miso,
    input                       s_read_vld
);

    localparam CMD_CNT_WIDTH  = $clog2(2*DATA_WIDTH) + 1;
    localparam SCLK_CNT_WIDTH = $clog2(SCLK_CNT) + 1;

    wire [SCLK_CNT_WIDTH - 1 : 0] clk_cnt;
    reg  [SCLK_CNT_WIDTH - 1 : 0] r_clk_cnt;
    wire                          send_cnt_done;
    wire                          rec_cnt_done;

    //cs_n和sclk由top产生
    reg r_cs_n;
    reg r_sclk;
    wire cmd_fire = cmd_vld && cmd_rdy;

    assign cs_n = r_cs_n;
    always @(posedge clk or negedge rst_n) begin //产生r_cs_n信号
        if(!rst_n) begin
            r_cs_n <= 1'b1;
        end
        else if(cmd_fire) begin
            r_cs_n <= 1'b0;
        end
        else if(send_cnt_done && !cs_n) begin
            r_cs_n <= 1'b1;
        end
        else if(s_read_vld) begin
            r_cs_n <= 1'b0;
        end
        else if(rec_cnt_done && !cs_n) begin
            r_cs_n <= 1'b1;
        end
    end

    assign sclk = r_sclk;
    always @(posedge clk or negedge rst_n) begin //产生sclk信号
        if(!rst_n) begin
            r_sclk <= 1'b0;
        end
        else if(!cs_n) begin
            if(clk_cnt == SCLK_CNT / 2) begin
                r_sclk <= 1'b1; 
            end
            else if(clk_cnt == SCLK_CNT) begin
                r_sclk <= 1'b0;
            end
        end
        else begin
            r_sclk <= 1'b0;
        end      
    end

    assign clk_cnt = r_clk_cnt;
    always @(posedge clk or negedge rst_n) begin //时钟计数器
        if(!rst_n) begin
            r_clk_cnt <= 'b0;
        end
        else if(!cs_n) begin
            r_clk_cnt <= r_clk_cnt + 1'b1;
            if(r_clk_cnt == SCLK_CNT) begin
                r_clk_cnt <= 'b0;
            end
        end
        // else begin
        //     r_clk_cnt <= r_clk_cnt;
        // end
    end

    spi_master_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .SCLK_CNT(SCLK_CNT)
        ) u_spi_master_tx(
        .clk(clk),
        .rst_n(rst_n),
        .cmd_in(cmd_in),
        .cmd_vld(cmd_vld),
        .cmd_rdy(cmd_rdy),
        .mosi(mosi),
        .send_cnt_done(send_cnt_done),
        .clk_cnt(clk_cnt),
        .cs_n(cs_n)
        );

    spi_master_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .SCLK_CNT(SCLK_CNT)
        ) u_spi_master_rx(
        .clk(clk),
        .rst_n(rst_n),
        .miso(miso),
        .s_read_vld(s_read_vld),
        .m_read_data(m_read_data),
        .m_read_vld(m_read_vld),
        .clk_cnt(clk_cnt),
        .cs_n(cs_n),
        .rec_cnt_done(rec_cnt_done)
        // .send_cnt_done(send_cnt_done)
        );

endmodule

//---------------------------------------------master_tx---------------------------------------------

module spi_master_tx #(
    parameter DATA_WIDTH = 8,
    parameter SCLK_CNT   = 10
)(
    input                          clk,
    input                          rst_n,
    input  [2*DATA_WIDTH : 0]      cmd_in,
    input                          cmd_vld,
    output                         cmd_rdy,
    output                         mosi,

    input [SCLK_CNT_WIDTH - 1 : 0] clk_cnt,
    output                         send_cnt_done,
    input                          cs_n
);
    localparam CMD_CNT_WIDTH  = $clog2(2*DATA_WIDTH) + 1;
    localparam SCLK_CNT_WIDTH = $clog2(SCLK_CNT) + 1;

    reg  [CMD_CNT_WIDTH-1 : 0]    send_cnt;

    reg  [2*DATA_WIDTH : 0]       r_cmd_in;
    wire                          cmd_fire;
    wire                          send_cnt_done;
    reg                           busy;
    wire                          cs_n;

    assign send_cnt_done = (send_cnt == 2*DATA_WIDTH) && (clk_cnt == SCLK_CNT);

    //handshake
    assign cmd_rdy = !busy;
    assign cmd_fire = cmd_rdy && cmd_vld;

    //control path
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            send_cnt <= 'b0; 
        end
        else if(!cs_n && (clk_cnt == SCLK_CNT)) begin
            send_cnt <= send_cnt + 1'b1;
            if(send_cnt_done) begin
                send_cnt <= 'b0;
            end
        end
        else if(cs_n) begin
            send_cnt <= 'b0;
        end
    end
    
    //data path
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_cmd_in <= 'b0;
        end
        else if(cmd_fire) begin
            r_cmd_in <= cmd_in;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            busy <= 'b0;
        end
        else begin
            if(cmd_fire) begin
               busy <= 1'b1; 
            end
            if(send_cnt_done) begin
                busy <= 1'b0;
            end
        end
    end

    // reg send_cnt_done_delay;
    // always @(posedge clk or negedge rst_n) begin
    //     if(!rst_n) begin
    //         send_cnt_done_delay <= 'b0;
    //     end
    //     else begin
    //         send_cnt_done_delay <= send_cnt_done;
    //         if(cs_n) begin
    //             send_cnt_done_delay <= 'b0;
    //         end
    //     end
    // end

    assign mosi = r_cmd_in[send_cnt];

endmodule

//---------------------------master_rx-----------------------------------

module spi_master_rx #(
    parameter DATA_WIDTH = 8,
    parameter SCLK_CNT   = 10
) (
    input                          clk,
    input                          rst_n,
    input                          miso,
    input                          s_read_vld,
    output                         m_read_vld,
    output [DATA_WIDTH-1 : 0]      m_read_data,

    input [SCLK_CNT_WIDTH - 1 : 0] clk_cnt,
    output                         rec_cnt_done,
    input                          cs_n
    // input                          send_cnt_done
);
    localparam CNT_WIDTH      = $clog2(DATA_WIDTH) + 1;
    localparam SCLK_CNT_WIDTH = $clog2(SCLK_CNT) + 1;

    reg [CNT_WIDTH-1 : 0] rec_cnt;
    reg [DATA_WIDTH-1 :0] r_read_data;

    reg                   rec_cnt_done_delay;

    assign rec_cnt_done = (rec_cnt == DATA_WIDTH - 1) && (clk_cnt == SCLK_CNT);

    //control path
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rec_cnt <= 'b0;
        end
        else if(!cs_n && (clk_cnt == SCLK_CNT) && s_read_vld_delay) begin
            rec_cnt <= rec_cnt + 1'b1;
                if(rec_cnt_done) begin
                    rec_cnt <= 'b0;
                end  
        end
        else if(cs_n) begin
            rec_cnt <= 'b0;
        end
    end
    
    reg s_read_vld_delay;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            s_read_vld_delay <= 'b0;
        end
        else if(cs_n) begin
            s_read_vld_delay <= s_read_vld;
        end
    end

    //data path
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rec_cnt_done_delay <= 'b0;
        end
        else begin
            rec_cnt_done_delay <= rec_cnt_done;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            r_read_data <= 'b0;
        end
        else if(!cs_n && (clk_cnt == SCLK_CNT)) begin
            r_read_data[rec_cnt] <= miso;
        end
    end

    assign m_read_vld = rec_cnt_done_delay;
    assign m_read_data = r_read_data;

endmodule

    

