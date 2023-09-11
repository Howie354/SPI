module spi #(
    parameter DATA_WIDTH = 8
) (
    input                       clk,
    input                       rst_n,
    input  [2*DATA_WIDTH : 0]   cmd_in,
    input                       cmd_vld,
    output                      cmd_rdy,
    output                      m_read_vld,
    output [DATA_WIDTH-1 : 0]   m_read_data
);

    wire    sclk;
    wire    cs_n;
    wire    mosi;
    wire    miso;
    wire    s_read_vld;

    spi_master_top #(
        .DATA_WIDTH(DATA_WIDTH)
        )u_spi_master_top(
        .clk(clk),
        .rst_n(rst_n),
        .cmd_in(cmd_in),
        .cmd_vld(cmd_vld),
        .cmd_rdy(cmd_rdy),
        .m_read_vld(m_read_vld),
        .m_read_data(m_read_data),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .s_read_vld(s_read_vld)
        );

    spi_slave_top #(
        .DATA_WIDTH(DATA_WIDTH)
        )u_spi_slave_top(
        .sclk(sclk),
        .rst_n(rst_n),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .s_read_vld(s_read_vld)
        );

    // spi_master_tx u_spi_master_tx(clk,rst_n,cmd_in,cmd_vld,cmd_rdy,sclk,cs_n,mosi);
    
    // spi_master_rx u_spi_master_rx(clk,rst_n,miso,slave_data_rdy,read_vld,read_data);

    // spi_slave_rx u_spi_slave_rx(sclk,rst_n,cs_n,mosi,slave_data_out,slave_data_vld);

    // spi_slave_tx u_spi_slave_tx(sclk,rst_n,slave_data_out,slave_data_vld,miso,slave_data_rdy);


endmodule

// //---------------------------------------------master_tx---------------------------------------------

// module spi_master_tx #(
//     parameter DATA_WIDTH = 8
// )(
//     input                       clk,
//     input                       rst_n,
//     input  [2*DATA_WIDTH-1 : 0] cmd_in,
//     input                       cmd_vld,
//     output                      cmd_rdy,
//     output                      sclk,
//     output                      cs_n,
//     output                      mosi
// );
//     localparam CNT_WIDTH = $clog2(2*DATA_WIDTH) + 1; 

//     reg [2*CNT_WIDTH-1 : 0]  data_cnt;
//     reg [2*DATA_WIDTH-1 : 0] r_cmd_in;
//     wire                     cmd_fire;
//     wire                     data_cnt_done;
//     reg                      busy; 

//     assign data_cnt_done = data_cnt == 2*DATA_WIDTH-1;

//     //handshake
//     assign cmd_rdy = !busy;
//     assign cmd_fire = cmd_rdy && cmd_vld ;

//     //control path
//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//            data_cnt <= 'b0; 
//         end
//         else if(!cs_n) begin
//             data_cnt <= data_cnt + 1'b1;
//             if(data_cnt_done) begin
//                 data_cnt <= 'b0;
//             end
//         end
//     end

//     //data path
//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//             r_cmd_in <= 'b0;
//         end
//         else if(cmd_fire) begin
//             r_cmd_in <= cmd_in;
//         end
//     end
    
//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//             busy <= 'b0;
//         end
//         else begin
//             if(cmd_fire) begin
//                busy <= 1'b1; 
//             end
//             if(data_cnt_done) begin
//                 busy <= 1'b0;
//             end
//         end
//     end

//     assign sclk = !clk; //sclk generate
//     assign cs_n = !busy; //cs_n generate 

//     assign mosi = r_cmd_in[data_cnt];

// endmodule

// //---------------------------master_rx-----------------------------------

// module spi_master_rx #(
//     parameter DATA_WIDTH = 8
// ) (
//     input                       clk,
//     input                       rst_n,
//     input                       miso,
//     input                       slave_data_rdy,
//     output                      read_vld,
//     output [DATA_WIDTH-1 : 0]   read_data
// );
//     localparam CNT_WIDTH = $clog2(DATA_WIDTH-1) + 1;

//     reg [CNT_WIDTH-1 : 0] data_cnt;
//     reg [DATA_WIDTH-1 :0] r_read_data;
//     reg                   data_cnt_end_delay;
//     wire                  data_cnt_end;
//     reg                   r_slave_data_rdy;

//     assign data_cnt_end = data_cnt == DATA_WIDTH-1;

//     //control path
//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//             data_cnt <= 'b0;
//         end
//         else if(r_slave_data_rdy) begin
//             data_cnt <= data_cnt + 1'b1;
//                 if(data_cnt_end) begin
//                     data_cnt <= 'b0;
//                 end  
//         end
//     end
    
//     //data path
//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//             r_slave_data_rdy <= 'b0;
//         end
//         else begin
//             if(slave_data_rdy) begin
//                 r_slave_data_rdy <= 1'b1;
//             end
//             if(data_cnt_end) begin
//                 r_slave_data_rdy <= 1'b0;
//             end
//         end
//     end

//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//             data_cnt_end_delay <= 'b0;
//         end
//         else begin
//             data_cnt_end_delay <= data_cnt_end;
//         end
//     end

//     always @(posedge clk or negedge rst_n) begin
//         if(!rst_n) begin
//             r_read_data <= 'b0;
//         end
//         else if(r_slave_data_rdy) begin
//             r_read_data <= {miso,(r_read_data[DATA_WIDTH-1 : 1])};
//         end
//     end

//     assign read_vld = data_cnt_end_delay;

//     assign read_data = r_read_data;

// endmodule

    

// //----------------------------------slave_rx----------------------------------

// module spi_slave_rx #(
//     parameter DATA_WIDTH = 8
// ) (
//     input                     sclk,
//     input                     rst_n,
//     input                     cs_n,
//     input                     mosi,
//     output [DATA_WIDTH-1 : 0] data_out,
//     output                    data_vld
// );
//     localparam CNT_WIDTH = $clog2(DATA_WIDTH-1) + 1;

//     reg [2*CNT_WIDTH-1 : 0]    data_cnt;
//  //   reg [DATA_WIDTH-1 : 0]   r_data_out;
//     reg [2*DATA_WIDTH-1 : 0] r_slave_data;
//     wire                     data_cnt_end;
//     reg                      data_cnt_end_delay;
//     reg [DATA_WIDTH-1 : 0]   mem [127 : 0];
//     wire                     wr_vld;
//     wire                     rd_vld;
//     wire [DATA_WIDTH-2 : 0]  slave_addr;
//     wire [DATA_WIDTH-1 : 0]  slave_data;

//     assign data_cnt_end = data_cnt == 2*DATA_WIDTH - 1;
//     assign wr_vld = data_cnt_end_delay && r_slave_data[2*DATA_WIDTH-1];
//     assign rd_vld = data_cnt_end_delay && !r_slave_data[2*DATA_WIDTH-1];
//     assign slave_addr = r_slave_data[2*DATA_WIDTH-2 : DATA_WIDTH];
//     assign slave_data = r_slave_data[DATA_WIDTH-1 : 0];

//     //control path
//     always @(posedge sclk or negedge rst_n) begin
//         if(!rst_n) begin
//             data_cnt <= 'b0;
//         end
//         else if(!cs_n)  begin
//             data_cnt <= data_cnt + 1'b1;
//                 if(data_cnt_end) begin
//                     data_cnt <= 'b0;
//                 end
//         end

//     end

//     //data path
//     always @(posedge sclk or negedge rst_n) begin
//         if(!rst_n) begin
//             r_slave_data <= 'b0;
//         end
//         else if(!cs_n) begin
//             r_slave_data <= {mosi,(r_slave_data[2*DATA_WIDTH-1 : 1])};
//         end
//     end

//     always @(posedge sclk or negedge rst_n) begin
//         if(!rst_n) begin
//             data_cnt_end_delay <= 'b0;
//         end
//         else begin
//             data_cnt_end_delay <= data_cnt_end;
//         end
//     end

//     //mem logic
//     integer i;
//     always @(posedge sclk or negedge rst_n) begin
//         if(!rst_n) begin
//             for(i = 0;i < 128;i = i + 1) begin
//                 mem[i] <= 'b0;
//             end
//         end
//         else if(wr_vld) begin
//             mem[slave_addr] = r_slave_data;
//         end
//     end

//     assign data_out = mem[slave_addr];
//     assign data_vld = rd_vld;

// endmodule

// //--------------------------------slave_tx------------------------------

// module spi_slave_tx #(
//     parameter DATA_WIDTH = 8
// ) (
//     input                    sclk,    
//     input                    rst_n,
//     input [DATA_WIDTH-1 : 0] rx_data_in,
//     input                    read_vld,
//     output                   miso,
//     output                   slave_data_rdy
// );

//     localparam CNT_WIDTH = $clog2(DATA_WIDTH-1) + 1; 

//     reg [CNT_WIDTH-1 : 0]  data_cnt;
//     reg [DATA_WIDTH-1 : 0] r_rx_data_in;
// //    reg                    r_data_cnt_end_delay;
//     wire                   data_cnt_end;
//     reg                    r_read_vld;

//     assign data_cnt_end = data_cnt == DATA_WIDTH - 1;

//     //control path
//     always @(posedge sclk or rst_n) begin
//         if(!rst_n) begin
//             data_cnt <= 'b0;
//         end
//         else if(r_read_vld) begin
//             data_cnt <= data_cnt + 1'b1;
//                 if(data_cnt_end) begin
//                     data_cnt <= 'b0;
//                 end
//         end
//     end
    
//     //data path
    
//     always @(posedge sclk or negedge rst_n) begin
//         if(!rst_n) begin
//             r_read_vld <= 'b0;
//         end
//         else begin
//             if(read_vld) begin
//                 r_read_vld <= 1'b1;
//             end
//             if(data_cnt_end) begin
//                 r_read_vld <= 1'b0;
//             end
//         end
//     end

//     always @(posedge sclk  or negedge rst_n) begin
//         if(!rst_n) begin
//             r_rx_data_in <= 'b0;
//         end
//         else begin
//             if(read_vld) begin
//                 r_rx_data_in <= rx_data_in;
//             end
//             if(data_cnt_end) begin
//                 r_rx_data_in <= 'b0;
//             end
//         end
//     end

// /*    always @(posedge sclk or negedge rst_n) begin
//         if(!rst_n) begin
//             r_data_cnt_end_delay <= 'b0;
//         end
//         else begin
//             r_data_cnt_end_delay <= data_cnt_end;
//         end
//     end */
    
//     assign slave_data_rdy = read_vld;
//     assign miso = r_rx_data_in[data_cnt];
// endmodule
