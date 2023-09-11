module spi_slave_top #(
    parameter DATA_WIDTH = 8
) (
    input  sclk,
    input  rst_n,
    input  cs_n,
    input  mosi,

    output miso,
    output s_read_vld
);

    wire [DATA_WIDTH-1 : 0] data_out;
    wire rd_vld;

    spi_slave_rx #(
        .DATA_WIDTH(DATA_WIDTH)
        )u_spi_slave_rx(
        .sclk(sclk),
        .rst_n(rst_n),
        .cs_n(cs_n),
        .mosi(mosi),
        .data_out(data_out),
        .s_read_vld(s_read_vld),
        .rd_vld(rd_vld)
        );

    spi_slave_tx #(
        .DATA_WIDTH(DATA_WIDTH)
        )u_spi_slave_tx(
        .sclk(sclk),
        .rst_n(rst_n),
        .cs_n(cs_n),
        .rx_data_in(data_out),
        .rd_vld(rd_vld),
        .miso(miso)
        );
    
endmodule

//----------------------------------slave_rx----------------------------------

module spi_slave_rx #(
    parameter DATA_WIDTH = 8
) (
    input                     sclk,
    input                     rst_n,
    input                     cs_n,
    input                     mosi,
    output [DATA_WIDTH-1 : 0] data_out,
    output                    s_read_vld,
    output                    rd_vld
);
    localparam CNT_WIDTH = $clog2(2*DATA_WIDTH) + 1;
    localparam DEPTH     = 1 << DATA_WIDTH;

    reg [CNT_WIDTH-1 : 0]  data_cnt;
 //   reg [DATA_WIDTH-1 : 0]   r_data_out;
    reg [2*DATA_WIDTH : 0] r_slave_data;
    wire                   data_cnt_end;
    reg                    data_cnt_end_delay;
    reg [DATA_WIDTH-1 : 0] mem [DEPTH - 1 : 0];
    wire                   wr_vld;
    wire                   rd_vld;
    wire [DATA_WIDTH-1 : 0] slave_data;
    wire [DATA_WIDTH-1 : 0] slave_addr;

    assign data_cnt_end = data_cnt == 2*DATA_WIDTH;
    assign wr_vld =  r_slave_data[2*DATA_WIDTH];
    assign rd_vld = !r_slave_data[2*DATA_WIDTH];
    assign slave_addr = r_slave_data[2*DATA_WIDTH - 1 : DATA_WIDTH];
    assign slave_data = r_slave_data[DATA_WIDTH - 1 : 0];

    //control path
    always @(posedge sclk or negedge rst_n) begin
        if(!rst_n) begin
            data_cnt <= 'b0;
        end
        else if(!cs_n)  begin
            data_cnt <= data_cnt + 1'b1;
                if(data_cnt_end) begin
                    data_cnt <= 'b0;
                end
        end
        else if(cs_n) begin
            data_cnt <= 'b0;
        end

    end

    //data path
    always @(posedge sclk) begin
        if(!cs_n) begin
            r_slave_data[data_cnt] <= mosi;
        end
    end

    always @(posedge sclk or negedge rst_n) begin
        if(!rst_n) begin
            data_cnt_end_delay <= 'b0;
        end
        else begin
            data_cnt_end_delay <= data_cnt_end;
        end
    end

    //mem logic
    integer i;
    reg [DATA_WIDTH - 1 : 0] r_data_out;
    always @(posedge sclk or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0;i < 127;i = i + 1) begin
                mem[i] <= 'b0;
            end
        end
        else if(wr_vld && data_cnt_end_delay) begin
            mem[slave_addr] <= r_slave_data;
        end
        else if(rd_vld && data_cnt_end_delay) begin
            r_data_out <= mem[slave_addr]; //slave_addr一直变怎么办
        end
    end

    //如何锁定住data_out让它不再随着r_slave_data而改变？
    assign data_out = r_data_out;
    assign s_read_vld = data_cnt_end_delay && rd_vld;

endmodule

//--------------------------------slave_tx------------------------------

module spi_slave_tx #(
    parameter DATA_WIDTH = 8
) (
    input                    sclk,    
    input                    rst_n,
    input                    cs_n,
    input [DATA_WIDTH-1 : 0] rx_data_in,
    input                    rd_vld,
    output                   miso
);

    localparam CNT_WIDTH = $clog2(DATA_WIDTH) + 1; 

    reg [CNT_WIDTH-1 : 0]  data_cnt;
    // reg [DATA_WIDTH-1 : 0] r_rx_data_in;
    wire                   data_cnt_end;

    assign data_cnt_end = data_cnt == DATA_WIDTH - 1;

    //control path
    always @(posedge sclk or rst_n) begin
        if(!rst_n) begin
            data_cnt <= 'b0;
        end
        else begin
            if(!cs_n) begin
                data_cnt <= data_cnt + 1'b1;
            end
            if(data_cnt_end) begin
                data_cnt <= 'b0;
            end
            if(cs_n) begin
                data_cnt <= 'b0;
            end
            if(!rd_vld) begin
                data_cnt <= 'b0;
            end
        end
    end
    
    //data path
    // always @(posedge sclk  or negedge rst_n) begin
    //     if(!rst_n) begin
    //         r_rx_data_in <= 'b0;
    //     end
    //     else begin
    //         r_rx_data_in <= rx_data_in; 
    //     end
    // end

    // always @(posedge sclk or negedge rst_n) begin
    //     if(rst_n) begin
    //         r_data_cnt_end_delay <= 'b0;
    //     end
    //     else begin
    //         r_data_cnt_end_delay <= data_cnt_end;
    //     end
    // end
    
    assign miso = rx_data_in[data_cnt];

endmodule