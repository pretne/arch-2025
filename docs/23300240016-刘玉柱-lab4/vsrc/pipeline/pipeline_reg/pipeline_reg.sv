`ifndef __PIPELINE_REG_SV
`define __PIPELINE_REG_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`else

`endif

module pipeline_reg
    import common::*;
    import pipes::*; (
        input logic clk, reset,
        input logic flushF, stallf, stalld, stalle, stallm, stall, stallpc, stall_raw,
        input ibus_req_t ireq,
        input ibus_resp_t iresp,
        input dbus_req_t dreq,
        input dbus_resp_t dresp,
        input fetch_data_t dataF_nxt,
        output fetch_data_t dataF,

        input decode_data_t dataD_nxt,
        output decode_data_t dataD,

        input execute_data_t dataE_nxt,
        output execute_data_t dataE,

        input memory_data_t dataM_nxt,
        output memory_data_t dataM,

        input writeback_data_t dataW_nxt,
        output writeback_data_t dataW,

        output logic need_nop,
        input u1 branch,
        input u1 branch_enable,
        input logic flushall
    );

    // always_ff @(posedge clk) begin
    // if(reset) begin
    //     state <= IDLE;
    //     dataF <= '0;
    //     dataD <= '0;
    //     dataE <= '0;
    //     dataM <= '0;
    //     dataW <= '0;
    //     temp_counter <= 0;
    // end
    // else begin
    //     case(state) 
    //         IDLE: begin
    //             dataF <= dataF_nxt;
    //             dataD <= dataD_nxt;
    //             dataE <= dataE_nxt;
    //             dataM <= dataM_nxt;
    //             dataW <= dataW_nxt;
    //             temp_counter <= 0;
    //             state <= TEMP;
    //         end
    //         TEMP: begin
    //             if(temp_counter < 15) begin
    //                 temp_counter <= temp_counter + 1;
    //             end
    //             else begin
    //                 state <= IDLE;
    //             end
    //         end
    //     endcase
    // end
    // end

    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         dataF <= '0;
    //     end 
    //     else if(stalld | stallm) begin
    //         dataF <= dataF;
    //     end
    //     else if (~iresp.data_ok) begin
    //         dataF.valid <= 0;
    //     end 
    //     else begin
    //         dataF <= dataF_nxt;
    //     end
    // end

    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         dataD <= '0;
    //     end 
    //     else if(stallm) begin
    //         dataD <= dataD;
    //     end
    //     else if(stalld) begin
    //         dataD.valid <= 0;
    //     end
    //     else begin
    //         dataD <= dataD_nxt;
    //     end
    // end

    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         dataE <= '0;
    //     end 
    //     else if(stallm) begin
    //         dataE <= dataE;
    //     end
    //     else begin
    //         dataE <= dataE_nxt;
    //     end
    // end

    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         dataM <= '0;
    //     end 
    //     else if (stallm) begin
    //         dataM.valid <= 0;
    //     end
    //     else begin
    //         dataM <= dataM_nxt;
    //     end
    // end
    
    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         dataW <= '0;
    //     end 
    //     else begin
    //         dataW <= dataW_nxt;
    //     end
    // end

    always_ff @(posedge clk) begin
        if (reset) begin
            dataF <= '0;
        end 
        // if (flushall) begin
        //     dataF.valid <= 0;
        // end
        else if(stalld | stallm) begin
            dataF <= dataF;
        end
        else if(branch) begin
            dataF <= '0;
        end
        else begin
            dataF <= dataF_nxt;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            dataD <= '0;
        end 
        else if(stalld) begin
            dataD <= '0;
        end
        else if(stallm) begin
            dataD <= dataD;
        end
        else if(branch) begin
            dataD <= '0;
        end
        else begin
            dataD <= dataD_nxt;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            dataE <= '0;
        end 
        else if(stallm) begin
            dataE <= dataE;
        end
        else if(branch) begin
            dataE <= '0;
        end
        else begin
            dataE <= dataE_nxt;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            dataM <= '0;
        end 
        else if(stallm) begin
            dataM <= dataM;
        end
        else begin
            dataM <= dataM_nxt;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin
            dataW <= '0;
        end 
        else begin
            dataW <= dataW_nxt;
        end
    end

    // state_t state;

    // always_ff @(posedge clk) begin
    //     if(reset) begin
    //         state <= IDLE;
    //     end
    //     else begin
    //         case (state)
    //             IDLE:
    //                 if(stall_raw) begin
    //                     state <= INSERT_NOP1;
    //                 end
    //             INSERT_NOP1: state <= IDLE;
    //             INSERT_NOP2: state <= IDLE;
    //             INSERT_NOP3: state <= IDLE;
    //         endcase
    //     end
    // end

    // assign need_nop = (state != IDLE);

    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         dataF <= '0;
    //         dataD <= '0;
    //         dataE <= '0;
    //         dataM <= '0;
    //         dataW <= '0;
    //     end 
    //     // else if (stall_raw) begin
    //     // // 插入气泡逻辑
    //     //     dataF <= dataF;          // 冻结 IF 阶段（PC 已由外部逻辑暂停）
    //     //     dataD <= dataD;             // 清零 ID 阶段（插入 NOP）
    //     //     dataE <= '0;             
    //     //     dataM <= dataM_nxt;             
    //     //     dataW <= dataW_nxt;      
    //     // end 
    //     // else if (need_nop) begin
    //     // // 插入气泡逻辑
    //     //     dataF <= dataF;          // 冻结 IF 阶段（PC 已由外部逻辑暂停）
    //     //     dataD <= dataD;             // 清零 ID 阶段（插入 NOP）
    //     //     dataE <= '0;             
    //     //     dataM <= '0;             
    //     //     dataW <= dataW_nxt;      
    //     // end 
    //     // else if (need_nop) begin
    //     //     dataF <= dataF;
    //     //     dataD <= '0;
    //     //     dataE <= dataE_nxt;
    //     //     dataM <= dataM_nxt;
    //     //     dataW <= dataW_nxt;
    //     // end
    //     else if (stall) begin
    //         dataF <= dataF;
    //         dataD <= dataD;
    //         dataE <= dataE;
    //         dataM <= dataM;
    //         dataW <= dataW;
    //     end
    //     else begin
    //         dataF <= dataF_nxt;
    //         dataD <= dataD_nxt;
    //         dataE <= dataE_nxt;
    //         dataM <= dataM_nxt;
    //         dataW <= dataW_nxt;
    //     end
    // end

    // always_ff @(posedge clk) begin
    //     if (reset) begin
    //         dataF <= '0;
    //         dataD <= '0;
    //         dataE <= '0;
    //         dataM <= '0;
    //         dataW <= '0;
    //     end else if (!stall) begin
    //         dataF <= dataF_nxt;
    //         dataD <= dataD_nxt;
    //         dataE <= dataE_nxt;
    //         dataM <= dataM_nxt;
    //         dataW <= dataW_nxt;
    //     end else begin
    //         dataF <= dataF;
    //         dataD <= dataD;
    //         dataE <= dataE;
    //         dataM <= dataM;
    //         dataW <= dataW;
    //     end
    // end


endmodule

`endif 