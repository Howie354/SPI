module tb_spi #(
    parameter DATA_WIDTH = 8,
    parameter HALF_CYCLE = 5
) (
);
    reg                      clk;
    reg                      rst_n;
    reg [2*DATA_WIDTH : 0]   cmd_in;
    reg                      cmd_vld;
    wire                     cmd_rdy;
    wire                     m_read_vld;
    wire [DATA_WIDTH-1 : 0]  m_read_data;
    wire                     cmd_fire;

    spi #(DATA_WIDTH) u_spi(clk,rst_n,cmd_in,cmd_vld,cmd_rdy,m_read_vld,m_read_data);
    
    initial begin
        clk = 1'b0;
        forever #HALF_CYCLE clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        #100
        rst_n = 1'b1;
        #10000 $finish();
    end

    assign cmd_fire = cmd_rdy && cmd_vld;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cmd_vld <= 1'b0;
        end
        else begin
            cmd_vld <= 1'b1;
        end
    end

    initial begin
        cmd_in <= 17'b11111111101010101;
        #400
        cmd_in <= 17'b01111111100000000;
    end

/*    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cmd_in <= 'b0;
        end
        else if(cmd_fire) begin
            cmd_in <= cmd_in + 1'b1;
        end
    end  */

    initial begin
        $dumpfile("test.vcd");  // 指定VCD文件的名字为wave.vcd，仿真信息将记录到此文件
        $dumpvars;  // 指定层次数为0，则tb_code 模块及其下面各层次的所有信号将被记录
    end

endmodule
